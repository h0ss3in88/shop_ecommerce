FROM node:7.2.0-alpine
ENV PORT 4600
ENV NODE_ENV development
ENV POSTGRES_HOST=balloonshopDB
ENV POSTGRES_DATABASE=balloonshop
ENV POSTGRES_USER=hussein
ENV POSTGRES_PASS=123456
COPY . /products_microservice
WORKDIR /products_microservice
COPY package*.json ./
RUN npm install
EXPOSE $PORT
CMD ["npm","start"]
