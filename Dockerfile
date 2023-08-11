FROM debian:latest AS builder

ADD . /ws-scrcpy
RUN apt update && apt install -y nodejs npm python3 make g++
WORKDIR /ws-scrcpy
RUN npm install
RUN npm run dist
WORKDIR dist
RUN npm install

FROM debian:latest AS runner
LABEL maintainer="The Slayer <slayer@technologydragonslayer.com>"

RUN apt update && apt install -y adb npm
COPY --from=builder /ws-scrcpy/dist /root/ws-scrcpy

WORKDIR /root/ws-scrcpy
CMD ["npm", "start"]
