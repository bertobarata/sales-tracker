import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyBZP5zHghVJ3q_z4X0QCFMyIUrnQF7uKzs",
  authDomain: "sales-tracker-403a6.firebaseapp.com",
  projectId: "sales-tracker-403a6",
  storageBucket: "sales-tracker-403a6.firebasestorage.app",
  messagingSenderId: "271308469604",
  appId: "1:271308469604:web:5799344e678b952d84b671"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();
