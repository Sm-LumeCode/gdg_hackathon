from flask import Flask, jsonify, render_template, request
import json
import math
import os
import re
import urllib.parse
import urllib.request
import firebase_admin
from firebase_admin import credentials, auth, firestore
import requests
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

try:
    import networkx as nx
    import osmnx as ox
except Exception:  # Allows local API work even before geo deps are installed.
    nx = None
    ox = None


app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
ZONES_FILE = os.path.join(DATA_DIR, "zones.json")
GRAPH_FILE = os.path.join(DATA_DIR, "bangalore_graph.graphml")
RESOURCES_FILE = os.path.join(DATA_DIR, "resources.json")
USERS_FILE = os.path.join(DATA_DIR, "users.json")


def load_env_file():
    env_path = os.path.join(BASE_DIR, ".env")
    if not os.path.exists(env_path):
        return
    with open(env_path, encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())


load_env_file()
GOOGLE_MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "")
FIREBASE_API_KEY = os.environ.get("FIREBASE_API_KEY", "")

# Initialize Firebase Admin
cred_path = os.path.join(BASE_DIR, "serviceAccountKey.json")
if os.path.exists(cred_path):
    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Firebase Admin initialized successfully.")
    except Exception as e:
        print(f"Failed to initialize Firebase Admin: {e}")
        db = None
else:
    print("Warning: serviceAccountKey.json not found. Firebase features will be disabled.")
    db = None

G = None
resources_cache = None

BANGALORE_FALLBACK_RESOURCES = {
    "ambulances": [
        {"id": "AMB_001", "name": "Victoria Hospital", "lat": 12.9635, "lon": 77.5739},
        {"id": "AMB_002", "name": "Manipal Hospital Old Airport Road", "lat": 12.9582, "lon": 77.6484},
        {"id": "AMB_003", "name": "St. John's Medical College Hospital", "lat": 12.9294, "lon": 77.6187},
        {"id": "AMB_004", "name": "Aster CMI Hospital", "lat": 13.0545, "lon": 77.5928},
        {"id": "AMB_005", "name": "Fortis Hospital Bannerghatta", "lat": 12.8958, "lon": 77.5996},
    ],
    "fire_stations": [
        {"id": "FIRE_001", "name": "High Grounds Fire Station", "lat": 12.9866, "lon": 77.5938},
        {"id": "FIRE_002", "name": "Indiranagar Fire Station", "lat": 12.9784, "lon": 77.6408},
        {"id": "FIRE_003", "name": "Jayanagar Fire Station", "lat": 12.9257, "lon": 77.5930},
        {"id": "FIRE_004", "name": "Whitefield Fire Station", "lat": 12.9698, "lon": 77.7500},
        {"id": "FIRE_005", "name": "Yeshwanthpur Fire Station", "lat": 13.0285, "lon": 77.5409},
    ],
}


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "GET,POST,DELETE,OPTIONS"
    return response


def ensure_data_dir():
    os.makedirs(DATA_DIR, exist_ok=True)


def safe_id(prefix, raw):
    slug = re.sub(r"[^A-Za-z0-9]+", "_", str(raw)).strip("_")
    return f"{prefix}_{slug[:48] or 'resource'}"


def load_graph():
    global G
    if G is not None:
        return G
    if ox is None:
        return None
    ensure_data_dir()
    try:
        if os.path.exists(GRAPH_FILE):
            print("Loading saved Bangalore graph...")
            G = ox.load_graphml(GRAPH_FILE)
        else:
            print("Downloading Bangalore road network (one-time)...")
            G = ox.graph_from_place("Bangalore, India", network_type="drive")
            ox.save_graphml(G, GRAPH_FILE)
    except Exception as exc:
        print(f"Graph unavailable, using straight-line fallback: {exc}")
        G = None
    return G


def load_resources():
    global resources_cache
    if resources_cache:
        return resources_cache
    ensure_data_dir()
    if os.path.exists(RESOURCES_FILE):
        with open(RESOURCES_FILE, encoding="utf-8") as f:
            resources_cache = json.load(f)
        return resources_cache

    resources = {"ambulances": [], "fire_stations": []}
    if ox is not None:
        try:
            hospitals = ox.features_from_place("Bangalore, India", tags={"amenity": "hospital"})
            fire_stations = ox.features_from_place("Bangalore, India", tags={"amenity": "fire_station"})

            for idx, row in hospitals.iterrows():
                geom = row.geometry
                point = geom if geom.geom_type == "Point" else geom.centroid
                resources["ambulances"].append({
                    "id": safe_id("AMB", idx),
                    "name": row.get("name") or f"Hospital {idx}",
                    "lat": float(point.y),
                    "lon": float(point.x),
                })

            for idx, row in fire_stations.iterrows():
                geom = row.geometry
                point = geom if geom.geom_type == "Point" else geom.centroid
                resources["fire_stations"].append({
                    "id": safe_id("FIRE", idx),
                    "name": row.get("name") or f"Fire Station {idx}",
                    "lat": float(point.y),
                    "lon": float(point.x),
                })
        except Exception as exc:
            print(f"OSM resources unavailable, using fallback data: {exc}")

    if not resources["ambulances"] or not resources["fire_stations"]:
        resources = BANGALORE_FALLBACK_RESOURCES

    with open(RESOURCES_FILE, "w", encoding="utf-8") as f:
        json.dump(resources, f, indent=2)
    resources_cache = resources
    return resources_cache


def haversine(lat1, lon1, lat2, lon2):
    radius_km = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    return radius_km * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def get_route(olat, olon, dlat, dlon):
    graph = load_graph()
    if graph is not None and ox is not None and nx is not None:
        try:
            orig = ox.distance.nearest_nodes(graph, olon, olat)
            dest = ox.distance.nearest_nodes(graph, dlon, dlat)
            path = nx.shortest_path(graph, orig, dest, weight="length")
            coords = [[graph.nodes[n]["y"], graph.nodes[n]["x"]] for n in path]
            length_m = nx.shortest_path_length(graph, orig, dest, weight="length")
            dist_km = round(length_m / 1000, 2)
            return {
                "coords": coords,
                "distance_km": dist_km,
                "eta_minutes": max(1, round((dist_km / 40) * 60)),
            }
        except Exception as exc:
            print(f"Route fallback used: {exc}")

    dist = haversine(olat, olon, dlat, dlon)
    return {
        "coords": [[olat, olon], [dlat, dlon]],
        "distance_km": round(dist, 2),
        "eta_minutes": max(1, round((dist / 40) * 60)),
    }


def find_nearest(zone_lat, zone_lon, rtype, top_n=10):
    key = "ambulances" if rtype == "ambulance" else "fire_stations"
    pool = load_resources()[key]
    ranked = sorted(pool, key=lambda r: haversine(zone_lat, zone_lon, r["lat"], r["lon"]))
    return ranked[:top_n]


def load_zones():
    ensure_data_dir()
    if os.path.exists(ZONES_FILE):
        with open(ZONES_FILE, encoding="utf-8") as f:
            return json.load(f)
    return []


def save_zones(zones):
    ensure_data_dir()
    with open(ZONES_FILE, "w", encoding="utf-8") as f:
        json.dump(zones, f, indent=2)


def next_zone_id(zones):
    numbers = []
    for zone in zones:
        match = re.match(r"Z(\d+)$", str(zone.get("id", "")))
        if match:
            numbers.append(int(match.group(1)))
    return f"Z{(max(numbers) + 1) if numbers else 1:03d}"

def load_users_local():
    ensure_data_dir()
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_users_local(users):
    ensure_data_dir()
    with open(USERS_FILE, "w", encoding="utf-8") as f:
        json.dump(users, f, indent=2)


def calculate_incident_score(incident):
    description = incident.get('description', '').lower()
    incident_type = incident.get('incidentType', '').lower()
    
    # Base score
    score = 40
    
    # 1. Parse Scale
    if "scale: group" in description:
        score += 20
        # Try to find specific size
        if "< 50" in description: score += 5
        elif "< 100" in description: score += 10
        elif "< 200" in description: score += 15
        elif "other" in description or "100+" in description: score += 20
    elif "scale: individual" in description:
        score += 5

    # 2. Keywords analysis
    high_priority = r"fire|explosion|collapse|trapped|critical|blood|unconscious|breath|heart|severe|death|dying"
    medium_priority = r"accident|injury|broken|leak|flood|smoke|fight|theft"
    
    if re.search(high_priority, description) or re.search(high_priority, incident_type):
        score += 35
    elif re.search(medium_priority, description) or re.search(medium_priority, incident_type):
        score += 15

    # 3. Crowd/Location context
    if re.search(r"many|crowd|school|building|hospital|mall|public|busy|road", description):
        score += 10

    # Ensure max 100
    final_score = min(100, score)
    
    # 4. Optional Gemini Refinement (if key available)
    gemini_key = os.environ.get("GEMINI_API_KEY")
    if gemini_key:
        try:
            prompt = f"Analyze this emergency report and provide a criticality score from 0-100. Type: {incident_type}. Report: {description}. Return ONLY the integer score."
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={gemini_key}"
            payload = {"contents": [{"parts": [{"text": prompt}]}]}
            res = requests.post(url, json=payload, timeout=5)
            if res.status_code == 200:
                text = res.json()["candidates"][0]["content"]["parts"][0]["text"].strip()
                ai_score = int(re.search(r"\d+", text).group())
                # Blend AI score with rule-based score (70% AI weight)
                final_score = int(final_score * 0.3 + ai_score * 0.7)
        except Exception as e:
            print(f"Gemini scoring failed, using rule-based score: {e}")

    return min(100, final_score)


def send_admin_email_alert(incident, score):
    admin_email = os.environ.get("ADMIN_EMAIL")
    smtp_user = os.environ.get("SMTP_USER")
    smtp_pass = os.environ.get("SMTP_PASSWORD")
    smtp_server = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.environ.get("SMTP_PORT", 587))

    if not all([admin_email, smtp_user, smtp_pass]):
        print("SMTP credentials or Admin email not configured. Alert logged to console only.")
        print(f"CRITICAL ALERT: Score {score} for incident {incident.get('incidentType')}")
        return

    try:
        msg = MIMEMultipart()
        msg['From'] = smtp_user
        msg['To'] = admin_email
        msg['Subject'] = f"CRITICAL EMERGENCY ALERT - Score: {score}"
        
        body = f"""
        URGENT: A high-severity incident has been reported.
        
        Severity Score: {score}
        Incident Type: {incident.get('incidentType')}
        Location: {incident.get('place')}
        Description: {incident.get('description')}
        Reported At: {incident.get('date')}
        
        Please deploy resources immediately via the Nexus Command Center.
        """
        msg.attach(MIMEText(body, 'plain'))

        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_user, smtp_pass)
        server.send_message(msg)
        server.quit()
        print(f"Critical alert email sent to {admin_email}")
    except Exception as e:
        print(f"Error sending email alert: {e}")


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/auth/signup", methods=["POST", "OPTIONS"])
def auth_signup():
    if request.method == "OPTIONS": return "", 204
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")
    name = data.get("name")
    role = data.get("role", "user")

    if not all([email, password, name]):
        return jsonify({"success": False, "message": "Missing fields"}), 400

    if db is None:
        # Local fallback
        users = load_users_local()
        if email in users:
            return jsonify({"success": False, "message": "Email already exists"}), 400
        
        user_id = str(int(math.fmod(hash(email), 1000000)))
        user_data = {
            "id": user_id,
            "email": email,
            "password": password,  # Storing plain text for local hackathon demo
            "name": name,
            "role": role,
            "incidents": []
        }
        users[email] = user_data
        save_users_local(users)
        return jsonify({"success": True, "user": user_data}), 201

    try:
        # Create user in Firebase Auth
        user_record = auth.create_user(
            email=email,
            password=password,
            display_name=name
        )
        # Save additional user data in Firestore
        user_data = {
            "id": user_record.uid,
            "email": email,
            "name": name,
            "role": role,
            "incidents": []
        }
        db.collection("users").document(user_record.uid).set(user_data)
        return jsonify({"success": True, "user": user_data}), 201
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 400


@app.route("/api/auth/login", methods=["POST", "OPTIONS"])
def auth_login():
    if request.method == "OPTIONS": return "", 204
    data = request.get_json() or {}
    email = data.get("email")
    password = data.get("password")

    if not all([email, password]):
        return jsonify({"success": False, "message": "Missing email or password"}), 400

    if db is None:
        # Local fallback
        users = load_users_local()
        user_data = users.get(email)
        if user_data and user_data.get("password") == password:
            return jsonify({"success": True, "user": user_data, "token": "local-token"}), 200
        return jsonify({"success": False, "message": "Invalid email or password"}), 401

    if not FIREBASE_API_KEY:
        return jsonify({"success": False, "message": "FIREBASE_API_KEY is not configured"}), 500
    if db is None:
        return jsonify({"success": False, "message": "Firebase Admin is not configured"}), 500

    # Verify password using Firebase Identity Toolkit REST API
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_API_KEY}"
    payload = {"email": email, "password": password, "returnSecureToken": True}
    try:
        res = requests.post(url, json=payload)
        res_data = res.json()
        if "error" in res_data:
            err_msg = res_data["error"]["message"]
            return jsonify({"success": False, "message": f"Login failed: {err_msg}"}), 401
        
        uid = res_data["localId"]
        
        # Get user data from Firestore
        user_doc = db.collection("users").document(uid).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
        else:
            user_data = {"id": uid, "email": email, "name": "Unknown", "role": "user", "incidents": []}
            
        return jsonify({"success": True, "user": user_data, "token": res_data["idToken"]}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@app.route("/api/incidents", methods=["GET", "OPTIONS"])
def get_incidents():
    if request.method == "OPTIONS": return "", 204
    if db is None:
        users = load_users_local()
        all_incidents = []
        for uemail, udata in users.items():
            for inc in udata.get("incidents", []):
                inc["userId"] = udata.get("id")
                inc["userName"] = udata.get("name")
                all_incidents.append(inc)
        all_incidents.sort(key=lambda x: x.get("date", ""), reverse=True)
        return jsonify(all_incidents), 200

    try:
        users = db.collection("users").stream()
        all_incidents = []
        for u in users:
            udata = u.to_dict()
            for inc in udata.get("incidents", []):
                inc["userId"] = udata.get("id")
                inc["userName"] = udata.get("name")
                all_incidents.append(inc)
        all_incidents.sort(key=lambda x: x.get("date", ""), reverse=True)
        return jsonify(all_incidents), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/incidents", methods=["POST", "OPTIONS"])
def create_incident():
    if request.method == "OPTIONS": return "", 204
    
    data = request.get_json() or {}
    user_id = data.get("userId")
    incident = data.get("incident")
    if not user_id or not incident:
        return jsonify({"error": "Missing data"}), 400

    if db is None:
        users = load_users_local()
        user_to_update = None
        for uemail, udata in users.items():
            if udata.get("id") == user_id:
                user_to_update = udata
                break
        
        if not user_to_update:
            return jsonify({"error": "User not found"}), 404
        
        incidents = user_to_update.get("incidents", [])
        
        # Calculate score and check for alerts
        score = calculate_incident_score(incident)
        incident["score"] = score
        if score > 90:
            send_admin_email_alert(incident, score)
            
        incidents.append(incident)
        user_to_update["incidents"] = incidents
        save_users_local(users)
        return jsonify({"success": True, "user": user_to_update}), 201

    try:
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()
        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404
        
        udata = user_doc.to_dict()
        incidents = udata.get("incidents", [])
        
        # Calculate score and check for alerts
        score = calculate_incident_score(incident)
        incident["score"] = score
        if score > 90:
            send_admin_email_alert(incident, score)
            
        incidents.append(incident)
        user_ref.update({"incidents": incidents})
        
        udata["incidents"] = incidents
        return jsonify({"success": True, "user": udata}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/incidents/<incident_id>", methods=["PUT", "OPTIONS"])
def update_incident(incident_id):
    if request.method == "OPTIONS": return "", 204

    data = request.get_json() or {}
    user_id = data.get("userId")
    updates = data.get("updates", {})
    if not user_id:
        return jsonify({"error": "Missing userId"}), 400

    if db is None:
        users = load_users_local()
        user_to_update = None
        for uemail, udata in users.items():
            if udata.get("id") == user_id:
                user_to_update = udata
                break
        
        if not user_to_update:
            return jsonify({"error": "User not found"}), 404
            
        incidents = user_to_update.get("incidents", [])
        for idx, inc in enumerate(incidents):
            if inc.get("id") == incident_id:
                incidents[idx].update(updates)
                break
                
        user_to_update["incidents"] = incidents
        save_users_local(users)
        return jsonify({"success": True, "user": user_to_update}), 200

    try:
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()
        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404
            
        udata = user_doc.to_dict()
        incidents = udata.get("incidents", [])
        for idx, inc in enumerate(incidents):
            if inc.get("id") == incident_id:
                incidents[idx].update(updates)
                break
                
        user_ref.update({"incidents": incidents})
        udata["incidents"] = incidents
        return jsonify({"success": True, "user": udata}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"ok": True, "graph_loaded": G is not None, "osmnx_available": ox is not None})


@app.route("/api/zones", methods=["GET"])
def get_zones():
    return jsonify(load_zones())


@app.route("/api/zones", methods=["POST", "OPTIONS"])
def create_zone():
    if request.method == "OPTIONS":
        return "", 204
    data = request.get_json(silent=True) or {}
    required = ["lat", "lon", "type", "severity"]
    missing = [field for field in required if field not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    zones = load_zones()
    zone = {
        "id": next_zone_id(zones),
        "name": data.get("name") or f"Zone {len(zones) + 1}",
        "lat": float(data["lat"]),
        "lon": float(data["lon"]),
        "type": "fire" if data["type"] == "fire" else "ambulance",
        "severity": int(data["severity"]),
        "status": "pending",
        "resource": None,
        "resource_name": None,
        "distance_km": None,
        "eta_minutes": None,
        "route": [],
    }
    zones.append(zone)
    save_zones(zones)
    return jsonify(zone), 201


@app.route("/api/allocate/<zone_id>", methods=["POST", "OPTIONS"])
def allocate(zone_id):
    if request.method == "OPTIONS":
        return "", 204
    zones = load_zones()
    zone = next((z for z in zones if z["id"] == zone_id), None)
    if not zone:
        return jsonify({"error": "Zone not found"}), 404
    if zone["status"] == "assigned":
        return jsonify({"message": "Already assigned", "zone": zone})

    candidates = find_nearest(zone["lat"], zone["lon"], zone["type"])
    taken = {z["resource"] for z in zones if z["status"] == "assigned" and z.get("resource")}
    available = [r for r in candidates if r["id"] not in taken]

    if not available:
        zone["status"] = "pending"
        save_zones(zones)
        return jsonify({"message": "No available resources", "zone": zone})

    best = available[0]
    result = get_route(zone["lat"], zone["lon"], best["lat"], best["lon"])
    zone.update({
        "status": "assigned",
        "resource": best["id"],
        "resource_name": best["name"],
        "resource_lat": best["lat"],
        "resource_lon": best["lon"],
        "distance_km": result["distance_km"],
        "eta_minutes": result["eta_minutes"],
        "route": result["coords"],
    })
    save_zones(zones)
    return jsonify({"message": "Assigned", "zone": zone})


@app.route("/api/zones/<zone_id>", methods=["DELETE", "OPTIONS"])
def delete_zone(zone_id):
    if request.method == "OPTIONS":
        return "", 204
    zones = [z for z in load_zones() if z["id"] != zone_id]
    save_zones(zones)
    return jsonify({"message": "Deleted"})


@app.route("/api/resources", methods=["GET"])
def get_resources():
    resources = load_resources()
    return jsonify({
        "ambulances": len(resources["ambulances"]),
        "fire_stations": len(resources["fire_stations"]),
        "items": resources,
    })


@app.route("/api/google/places/autocomplete", methods=["GET"])
def google_places_autocomplete():
    query = (request.args.get("q") or "").strip()
    if len(query) < 2:
        return jsonify({"predictions": []})
    if not GOOGLE_MAPS_API_KEY:
        return jsonify({"error": "GOOGLE_MAPS_API_KEY is not configured", "predictions": []}), 503

    params = urllib.parse.urlencode({
        "input": query,
        "key": GOOGLE_MAPS_API_KEY,
        "components": "country:in",
        "location": "12.9716,77.5946",
        "radius": "60000",
    })
    url = f"https://maps.googleapis.com/maps/api/place/autocomplete/json?{params}"
    try:
        with urllib.request.urlopen(url, timeout=8) as response:
            data = json.loads(response.read().decode("utf-8"))
        predictions = [
            {
                "description": item.get("description"),
                "place_id": item.get("place_id"),
            }
            for item in data.get("predictions", [])
        ]
        return jsonify({"predictions": predictions, "status": data.get("status")})
    except Exception as exc:
        return jsonify({"error": str(exc), "predictions": []}), 502


@app.route("/api/google/places/details", methods=["GET"])
def google_place_details():
    place_id = (request.args.get("place_id") or "").strip()
    if not place_id:
        return jsonify({"error": "place_id is required"}), 400
    if not GOOGLE_MAPS_API_KEY:
        return jsonify({"error": "GOOGLE_MAPS_API_KEY is not configured"}), 503

    params = urllib.parse.urlencode({
        "place_id": place_id,
        "key": GOOGLE_MAPS_API_KEY,
        "fields": "formatted_address,name,geometry",
    })
    url = f"https://maps.googleapis.com/maps/api/place/details/json?{params}"
    try:
        with urllib.request.urlopen(url, timeout=8) as response:
            data = json.loads(response.read().decode("utf-8"))
        result = data.get("result", {})
        location = result.get("geometry", {}).get("location", {})
        return jsonify({
            "name": result.get("name"),
            "formatted_address": result.get("formatted_address"),
            "lat": location.get("lat"),
            "lon": location.get("lng"),
            "status": data.get("status"),
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 502


if __name__ == "__main__":
    ensure_data_dir()
    load_resources()
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_ENV") != "production"
    app.run(host="0.0.0.0", port=port, debug=debug, use_reloader=False)
