// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCVSxXi5f74lgB7CQIhvc2RTTGJ-I1Jvgc",
  authDomain: "sempre-online-notificacoes.firebaseapp.com",
  projectId: "sempre-online-notificacoes",
  storageBucket: "sempre-online-notificacoes.firebasestorage.app",
  messagingSenderId: "626864649467",
  appId: "1:626864649467:web:399405db0e3d78be5c6c5e"
});

const messaging = firebase.messaging();
