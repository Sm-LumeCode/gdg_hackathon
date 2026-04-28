import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { CrisisProvider } from './context/CrisisContext'
import { AuthProvider } from './context/AuthContext'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <AuthProvider>
      <CrisisProvider>
        <App />
      </CrisisProvider>
    </AuthProvider>
  </React.StrictMode>,
)
