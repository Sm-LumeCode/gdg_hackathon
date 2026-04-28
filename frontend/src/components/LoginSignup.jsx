import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';

export default function LoginSignup() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState('user');
  const [referralCode, setReferralCode] = useState('');
  const [error, setError] = useState('');

  const { login, signup } = useAuth();

  const handleSubmit = (e) => {
    e.preventDefault();
    setError('');

    if (isLogin) {
      const result = login(email, password);
      if (!result.success) {
        setError(result.message);
      }
    } else {
      if (role === 'volunteer' && referralCode !== 'qwerty') {
        setError('Invalid referral code for volunteer');
        return;
      }
      const result = signup({ email, password, name, role });
      if (!result.success) {
        setError(result.message);
      }
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-[#182024] text-gray-300 font-sans">
      <div className="w-full max-w-md p-8 bg-[#1c252a] rounded-xl shadow-2xl border border-[#2a343a]/50">
        <div className="flex flex-col items-center mb-8">
          <div className="text-[#00d68f] mb-4">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M4 4L10 20H14L8 4H4Z" fill="currentColor"/>
              <path d="M14 4L20 20H16L10 4H14Z" fill="currentColor"/>
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-white tracking-widest uppercase">
            {isLogin ? 'Login to Command' : 'Join Command'}
          </h2>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-500/20 border border-red-500/50 rounded text-red-400 text-sm text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {!isLogin && (
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-1">Full Name</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-[#182024] text-sm text-gray-200 border border-[#2a343a] rounded-lg px-4 py-3 focus:outline-none focus:border-[#00d68f] transition-colors"
                placeholder="John Doe"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-400 mb-1">Email Address</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-[#182024] text-sm text-gray-200 border border-[#2a343a] rounded-lg px-4 py-3 focus:outline-none focus:border-[#00d68f] transition-colors"
              placeholder="you@example.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-400 mb-1">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-[#182024] text-sm text-gray-200 border border-[#2a343a] rounded-lg px-4 py-3 focus:outline-none focus:border-[#00d68f] transition-colors"
              placeholder="••••••••"
            />
          </div>

          {!isLogin && (
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-1">Select Role</label>
              <div className="flex gap-4">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="role"
                    value="user"
                    checked={role === 'user'}
                    onChange={() => setRole('user')}
                    className="accent-[#00d68f]"
                  />
                  <span>User</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="role"
                    value="volunteer"
                    checked={role === 'volunteer'}
                    onChange={() => setRole('volunteer')}
                    className="accent-[#00d68f]"
                  />
                  <span>Volunteer</span>
                </label>
              </div>
            </div>
          )}

          {!isLogin && role === 'volunteer' && (
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-1">Referral Code</label>
              <input
                type="text"
                required
                value={referralCode}
                onChange={(e) => setReferralCode(e.target.value)}
                className="w-full bg-[#182024] text-sm text-gray-200 border border-[#2a343a] rounded-lg px-4 py-3 focus:outline-none focus:border-[#00d68f] transition-colors"
                placeholder="Enter volunteer referral code"
              />
            </div>
          )}

          <button
            type="submit"
            className="w-full bg-[#00d68f] hover:bg-[#00c080] text-[#182024] font-bold py-3 rounded-lg transition-colors mt-6"
          >
            {isLogin ? 'Sign In' : 'Create Account'}
          </button>
        </form>

        <div className="mt-6 text-center">
          <button
            onClick={() => {
              setIsLogin(!isLogin);
              setError('');
            }}
            className="text-sm text-[#00d68f] hover:text-[#00c080] transition-colors"
          >
            {isLogin ? "Don't have an account? Sign up" : "Already have an account? Log in"}
          </button>
        </div>
      </div>
    </div>
  );
}
