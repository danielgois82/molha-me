FROM node:22.20.0-alpine

WORKDIR /usr/src/app

RUN npm install express cors pg

COPY . .

EXPOSE 3000

CMD [ "node", "api_simples.js" ]
