const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

app.use('/api', createProxyMiddleware({
  target: 'https://sistema.semppreonline.com.br/webservice/v1',
  changeOrigin: true,
  pathRewrite: {
    '^/api': ''
  },
  secure: false,
}));

app.listen(3000, () => {
  console.log('🚀 Proxy rodando em http://localhost:3000');
});
