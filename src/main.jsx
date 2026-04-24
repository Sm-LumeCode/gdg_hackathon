import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { CrisisProvider } from './context/CrisisContext'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <CrisisProvider>
      <App />
    </CrisisProvider>
  </React.StrictMode>,
)
