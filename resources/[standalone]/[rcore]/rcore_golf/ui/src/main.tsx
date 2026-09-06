import React from 'react';
import ReactDOM from 'react-dom/client';
import { VisibilityProvider } from './providers/VisibilityProvider';
import { SourceProvider } from './providers/SourceProvider'
import App from './components/App';
import './index.css';
import { TranslationProvider } from './providers/TranslationProvider';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <VisibilityProvider>
      <SourceProvider>
        <TranslationProvider>
          <App />
        </TranslationProvider>
      </SourceProvider>
    </VisibilityProvider>
  </React.StrictMode>,
);
