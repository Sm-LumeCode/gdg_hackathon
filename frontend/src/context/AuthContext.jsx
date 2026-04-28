import React, { createContext, useContext, useState, useEffect } from 'react';
import { getRemainingSeconds } from '../allotmentLogic';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [users, setUsers] = useState([]);

  useEffect(() => {
    // Load from local storage
    const storedUsers = localStorage.getItem('crisis_users');
    const storedCurrentUser = localStorage.getItem('crisis_current_user');
    
    if (storedUsers) {
      setUsers(JSON.parse(storedUsers));
    }
    if (storedCurrentUser) {
      setCurrentUser(JSON.parse(storedCurrentUser));
    }
  }, []);

  useEffect(() => {
    const completeExpiredAssignments = () => {
      let changed = false;
      const updatedUsers = users.map(user => {
        const incidents = (user.incidents || []).map(incident => {
          if (incident.status === 'assigned' && getRemainingSeconds(incident) <= 0) {
            changed = true;
            return { ...incident, status: 'completed', completedAt: new Date().toISOString() };
          }
          return incident;
        });
        return incidents === user.incidents ? user : { ...user, incidents };
      });

      if (!changed) return;
      setUsers(updatedUsers);
      localStorage.setItem('crisis_users', JSON.stringify(updatedUsers));

      if (currentUser) {
        const updatedCurrentUser = updatedUsers.find(user => user.id === currentUser.id);
        if (updatedCurrentUser) {
          setCurrentUser(updatedCurrentUser);
          localStorage.setItem('crisis_current_user', JSON.stringify(updatedCurrentUser));
        }
      }
    };

    completeExpiredAssignments();
    const timer = setInterval(completeExpiredAssignments, 1000);
    return () => clearInterval(timer);
  }, [users, currentUser]);

  const login = (email, password) => {
    const user = users.find(u => u.email === email && u.password === password);
    if (user) {
      setCurrentUser(user);
      localStorage.setItem('crisis_current_user', JSON.stringify(user));
      return { success: true };
    }
    return { success: false, message: 'Invalid credentials' };
  };

  const signup = (userData) => {
    if (users.find(u => u.email === userData.email)) {
      return { success: false, message: 'Email already exists' };
    }
    const newUser = { 
      ...userData, 
      id: Date.now().toString(),
      incidents: [] // To store incidents reported by this user
    };
    const newUsers = [...users, newUser];
    setUsers(newUsers);
    setCurrentUser(newUser);
    
    localStorage.setItem('crisis_users', JSON.stringify(newUsers));
    localStorage.setItem('crisis_current_user', JSON.stringify(newUser));
    
    return { success: true };
  };

  const logout = () => {
    setCurrentUser(null);
    localStorage.removeItem('crisis_current_user');
  };

  const addIncident = (incident) => {
    if (!currentUser) return;
    const newIncident = {
      ...incident,
      id: Date.now().toString(),
      status: 'pending',
      date: new Date().toISOString(),
      score: null // initially null
    };
    
    const updatedUser = {
      ...currentUser,
      incidents: [...(currentUser.incidents || []), newIncident]
    };
    
    setCurrentUser(updatedUser);
    localStorage.setItem('crisis_current_user', JSON.stringify(updatedUser));
    
    const updatedUsers = users.map(u => u.id === currentUser.id ? updatedUser : u);
    setUsers(updatedUsers);
    localStorage.setItem('crisis_users', JSON.stringify(updatedUsers));
  };

  const getAllIncidents = () => {
    let all = [];
    users.forEach(u => {
      if (u.incidents) {
        u.incidents.forEach(inc => {
          all.push({ ...inc, userId: u.id, userName: u.name });
        });
      }
    });
    return all.sort((a, b) => new Date(b.date) - new Date(a.date));
  };

  const updateIncident = (incidentId, userId, updates) => {
    const updatedUsers = users.map(u => {
      if (u.id === userId) {
        return {
          ...u,
          incidents: u.incidents.map(inc => inc.id === incidentId ? { ...inc, ...updates } : inc)
        };
      }
      return u;
    });

    setUsers(updatedUsers);
    localStorage.setItem('crisis_users', JSON.stringify(updatedUsers));
    
    if (currentUser && currentUser.id === userId) {
      const updatedCurrentUser = updatedUsers.find(u => u.id === userId);
      setCurrentUser(updatedCurrentUser);
      localStorage.setItem('crisis_current_user', JSON.stringify(updatedCurrentUser));
    }
  };

  const updateUser = (userId, updates) => {
    const updatedUsers = users.map(u => {
      if (u.id === userId) {
        return { ...u, ...updates };
      }
      return u;
    });

    setUsers(updatedUsers);
    localStorage.setItem('crisis_users', JSON.stringify(updatedUsers));
    
    if (currentUser && currentUser.id === userId) {
      const updatedCurrentUser = updatedUsers.find(u => u.id === userId);
      setCurrentUser(updatedCurrentUser);
      localStorage.setItem('crisis_current_user', JSON.stringify(updatedCurrentUser));
    }
  };

  return (
    <AuthContext.Provider value={{ currentUser, users, login, signup, logout, addIncident, getAllIncidents, updateIncident, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
