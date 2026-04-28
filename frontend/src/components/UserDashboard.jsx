import React, { useState, useRef } from 'react';
import { useAuth } from '../context/AuthContext';
import { Send, Plus, Image as ImageIcon, X, CheckCircle, MapPin, Loader2 } from 'lucide-react';

export default function UserDashboard() {
  const { addIncident } = useAuth();
  const [step, setStep] = useState(1);
  const [description, setDescription] = useState('');
  const [image, setImage] = useState(null);
  const [incidentType, setIncidentType] = useState('');
  const [place, setPlace] = useState('');
  const [showPopup, setShowPopup] = useState(false);
  const [isLocating, setIsLocating] = useState(false);
  
  const fileInputRef = useRef(null);

  const handleInitialSubmit = (e) => {
    e.preventDefault();
    if (!description.trim() && !image) return;
    setStep(2);
  };

  const handleFinalSubmit = (e) => {
    e.preventDefault();
    if (!incidentType.trim() || !place.trim()) return;
    
    addIncident({
      description,
      image,
      incidentType,
      place
    });
    
    // Reset
    setStep(1);
    setDescription('');
    setImage(null);
    setIncidentType('');
    setPlace('');
    
    setShowPopup(true);
    setTimeout(() => setShowPopup(false), 4000);
  };

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImage(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleGetLocation = () => {
    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser");
      return;
    }
    
    setIsLocating(true);
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords;
        try {
          const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`);
          const data = await res.json();
          if (data && data.display_name) {
            // Use a shorter version of the display name if possible, or the whole thing
            const parts = data.display_name.split(',');
            setPlace(parts.slice(0, 3).join(', '));
          } else {
            setPlace(`${latitude.toFixed(5)}, ${longitude.toFixed(5)}`);
          }
        } catch (error) {
          setPlace(`${latitude.toFixed(5)}, ${longitude.toFixed(5)}`);
        }
        setIsLocating(false);
      },
      () => {
        alert("Unable to retrieve your location");
        setIsLocating(false);
      }
    );
  };

  return (
    <div className="h-full flex flex-col items-center justify-center p-4 relative">
      <div className="w-full max-w-2xl bg-[#182024] rounded-2xl shadow-xl border border-[#2a343a]/50 p-6 flex flex-col min-h-[400px]">
        
        <div className="flex-1 overflow-y-auto mb-6">
          {step === 1 ? (
            <div className="flex flex-col items-center justify-center h-full text-center space-y-4">
              <div className="w-16 h-16 bg-[#2a343a] rounded-full flex items-center justify-center mb-2">
                <Send className="text-[#00d68f]" size={28} />
              </div>
              <h2 className="text-2xl font-bold text-white">Report an Incident</h2>
              <p className="text-gray-400 max-w-md">
                Describe the incident you are witnessing. You can also upload a photo for better context.
              </p>
            </div>
          ) : (
            <div className="flex flex-col h-full space-y-6">
              <div className="bg-[#1c252a] p-4 rounded-xl border border-[#2a343a]">
                <h3 className="text-[#00d68f] font-semibold mb-2">Initial Report</h3>
                <p className="text-gray-300">{description}</p>
                {image && (
                  <img src={image} alt="Incident" className="mt-4 rounded-lg max-h-48 object-cover" />
                )}
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-white mb-4">Please provide more details</h3>
                <form onSubmit={handleFinalSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Incident Type</label>
                    <input
                      type="text"
                      required
                      value={incidentType}
                      onChange={(e) => setIncidentType(e.target.value)}
                      placeholder="e.g. Fire, Medical Emergency, Accident"
                      className="w-full bg-[#1c252a] text-sm text-gray-200 border border-[#2a343a] rounded-lg px-4 py-3 focus:outline-none focus:border-[#00d68f] transition-colors"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-400 mb-1">Location / Place</label>
                    <div className="relative">
                      <input
                        type="text"
                        required
                        value={place}
                        onChange={(e) => setPlace(e.target.value)}
                        placeholder="e.g. Main Street, Downtown"
                        className="w-full bg-[#1c252a] text-sm text-gray-200 border border-[#2a343a] rounded-lg pl-4 pr-12 py-3 focus:outline-none focus:border-[#00d68f] transition-colors"
                      />
                      <button
                        type="button"
                        onClick={handleGetLocation}
                        disabled={isLocating}
                        className="absolute right-2 top-1/2 -translate-y-1/2 p-2 text-gray-400 hover:text-[#00d68f] transition-colors disabled:opacity-50"
                        title="Get current location"
                      >
                        {isLocating ? <Loader2 className="animate-spin" size={18} /> : <MapPin size={18} />}
                      </button>
                    </div>
                  </div>
                  <div className="pt-4 flex gap-3">
                    <button
                      type="button"
                      onClick={() => setStep(1)}
                      className="flex-1 bg-[#2a343a] hover:bg-[#323d44] text-white font-medium py-3 rounded-lg transition-colors"
                    >
                      Back
                    </button>
                    <button
                      type="submit"
                      className="flex-1 bg-[#00d68f] hover:bg-[#00c080] text-[#182024] font-bold py-3 rounded-lg transition-colors"
                    >
                      Confirm & Report
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>

        {step === 1 && (
          <form onSubmit={handleInitialSubmit} className="relative">
            {image && (
              <div className="absolute -top-20 left-0 bg-[#1c252a] p-2 rounded-lg border border-[#2a343a] flex items-center gap-2">
                <img src={image} alt="Preview" className="w-12 h-12 object-cover rounded" />
                <button 
                  type="button" 
                  onClick={() => setImage(null)}
                  className="p-1 hover:bg-[#2a343a] rounded-full text-gray-400 hover:text-white"
                >
                  <X size={16} />
                </button>
              </div>
            )}
            <div className="flex items-end bg-[#1c252a] rounded-2xl border border-[#2a343a] p-2 focus-within:border-[#00d68f] transition-colors">
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="p-3 text-gray-400 hover:text-[#00d68f] transition-colors rounded-xl hover:bg-[#2a343a]"
              >
                <Plus size={24} />
              </button>
              <input 
                type="file" 
                ref={fileInputRef} 
                onChange={handleImageUpload} 
                accept="image/*" 
                className="hidden" 
              />
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Type about the incident..."
                className="flex-1 bg-transparent text-gray-200 px-4 py-3 max-h-32 min-h-[50px] resize-none focus:outline-none"
                rows={1}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleInitialSubmit(e);
                  }
                }}
              />
              <button
                type="submit"
                disabled={!description.trim() && !image}
                className={`p-3 rounded-xl transition-colors ${
                  description.trim() || image 
                    ? 'bg-[#00d68f] text-[#182024] hover:bg-[#00c080]' 
                    : 'bg-[#2a343a] text-gray-500 cursor-not-allowed'
                }`}
              >
                <Send size={20} />
              </button>
            </div>
          </form>
        )}
      </div>

      {/* Custom Popup Toast */}
      {showPopup && (
        <div className="fixed bottom-8 right-8 z-50 bg-[#1c252a] border border-[#00d68f]/50 shadow-[0_4px_20px_rgba(0,214,143,0.15)] rounded-xl p-4 flex items-start gap-4 transition-all duration-300 ease-out transform translate-y-0 opacity-100">
          <div className="mt-1">
            <CheckCircle className="text-[#00d68f]" size={24} />
          </div>
          <div className="flex-1">
            <h4 className="text-white font-bold mb-1">Incident Reported!</h4>
            <p className="text-sm text-gray-400">Your incident has been successfully logged.</p>
          </div>
          <button 
            onClick={() => setShowPopup(false)} 
            className="text-gray-500 hover:text-white transition-colors"
          >
            <X size={18} />
          </button>
        </div>
      )}
    </div>
  );
}
