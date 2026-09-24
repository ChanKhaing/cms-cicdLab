# ── Stage 1: Builder ──────────────────────────────────────
# node_modules နဲ့ TypeScript compile လုပ်တဲ့ stage
FROM node:18-alpine AS builder

WORKDIR /app

# package files တွေကို အရင် copy (layer cache ကို အကျိုးရှိရှိ သုံးဖို့)
COPY package*.json ./
RUN npm ci --only=production

# compiled JS files copy
COPY dist/ ./dist/

# ── Stage 2: Runner ───────────────────────────────────────
# final lightweight image — builder ကနေ လိုတာပဲ ယူတယ်
FROM node:18-alpine AS runner

WORKDIR /app

# production dependencies + compiled code သာ ယူတယ်
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./

EXPOSE 3000

CMD ["node", "dist/app.js"]
