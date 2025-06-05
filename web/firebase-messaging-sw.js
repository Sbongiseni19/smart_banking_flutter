// firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBPTLW0QAgf5rs_fKUsPclFHHpiH0QqMXU",
  authDomain: "smartbankingapp-b25a0.firebaseapp.com",
  projectId: "smartbankingapp-b25a0",
  storageBucket: "smartbankingapp-b25a0.appspot.com",
  messagingSenderId: "60243541943",
  appId: "1:60243541943:web:2d0022da90c8ba12ae3232"
});

const messaging = firebase.messaging();
