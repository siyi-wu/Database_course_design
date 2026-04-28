import express from "express";
import mysql from "mysql2/promise";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "../..");
const configPath = path.join(rootDir, "config.txt");
const port = Number(process.env.PORT || 3001);

function readDbConfig() {
  const text = fs.readFileSync(configPath, "utf8");
  const pick = (key) => {
    const match = text.match(new RegExp(`${key}\\s*:\\s*(.+)`, "i"));
    return match?.[1]?.trim();
  };

  return {
    host: pick("host"),
    port: Number(pick("port") || 3306),
    user: pick("username"),
    password: pick("password"),
    database: pick("database"),
    waitForConnections: true,
    connectionLimit: 10,
    namedPlaceholders: true,
    multipleStatements: false,
    dateStrings: true,
    charset: "utf8mb4"
  };
}

const pool = mysql.createPool(readDbConfig());
const app = express();

app.use(express.json({ limit: "1mb" }));

function toInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function like(value) {
  return `%${String(value || "").trim()}%`;
}

function sendError(res, error) {
  const message = error?.sqlMessage || error?.message || "数据库操作失败";
  res.status(400).json({ error: message });
}

async function query(res, sql, params = {}) {
  try {
    const [rows] = await pool.query(sql, params);
    res.json(rows);
  } catch (error) {
    sendError(res, error);
  }
}

async function execute(res, sql, params = {}, success = {}) {
  try {
    const [result] = await pool.execute(sql, params);
    res.json({ ok: true, ...success, result });
  } catch (error) {
    sendError(res, error);
  }
}

app.get("/api/health", async (_req, res) => {
  try {
    const [rows] = await pool.query("SELECT DATABASE() AS database_name, NOW() AS server_time");
    res.json({ ok: true, ...rows[0] });
  } catch (error) {
    sendError(res, error);
  }
});

app.get("/api/stats", async (_req, res) => {
  try {
    const [[equipment]] = await pool.query(`
      SELECT
        COUNT(*) AS total,
        SUM(status = 'Available') AS available,
        SUM(status = 'Borrowed') AS borrowed,
        SUM(status = 'Maintenance') AS maintenance,
        SUM(status = 'Scrapped') AS scrapped
      FROM equipments
    `);
    const [[records]] = await pool.query(`
      SELECT
        COUNT(*) AS total_records,
        SUM(actual_return_date IS NULL) AS active_records,
        SUM(actual_return_date IS NULL AND plan_return_date < CURRENT_DATE()) AS overdue_records
      FROM borrowrecords
    `);
    const [[users]] = await pool.query("SELECT COUNT(*) AS total_users FROM users");
    const [[rooms]] = await pool.query("SELECT COUNT(*) AS total_rooms FROM labrooms");
    res.json({ ...equipment, ...records, ...users, ...rooms });
  } catch (error) {
    sendError(res, error);
  }
});

app.get("/api/categories", (_req, res) => {
  query(res, "SELECT category_id, category_name, description FROM categories ORDER BY category_id");
});

app.post("/api/categories", (req, res) => {
  const { category_name, description } = req.body;
  execute(res, "INSERT INTO categories (category_name, description) VALUES (:category_name, :description)", {
    category_name,
    description: description || null
  });
});

app.put("/api/categories/:id", (req, res) => {
  const { category_name, description } = req.body;
  execute(res, "UPDATE categories SET category_name = :category_name, description = :description WHERE category_id = :id", {
    id: req.params.id,
    category_name,
    description: description || null
  });
});

app.delete("/api/categories/:id", (req, res) => {
  execute(res, "DELETE FROM categories WHERE category_id = :id", { id: req.params.id });
});

app.get("/api/rooms", (_req, res) => {
  query(res, "SELECT room_id, room_name, location, admin_name FROM labrooms ORDER BY room_id");
});

app.post("/api/rooms", (req, res) => {
  const { room_name, location, admin_name } = req.body;
  execute(res, "INSERT INTO labrooms (room_name, location, admin_name) VALUES (:room_name, :location, :admin_name)", {
    room_name,
    location: location || null,
    admin_name: admin_name || null
  });
});

app.put("/api/rooms/:id", (req, res) => {
  const { room_name, location, admin_name } = req.body;
  execute(res, "UPDATE labrooms SET room_name = :room_name, location = :location, admin_name = :admin_name WHERE room_id = :id", {
    id: req.params.id,
    room_name,
    location: location || null,
    admin_name: admin_name || null
  });
});

app.delete("/api/rooms/:id", (req, res) => {
  execute(res, "DELETE FROM labrooms WHERE room_id = :id", { id: req.params.id });
});

app.get("/api/users", (req, res) => {
  const q = String(req.query.q || "").trim();
  const limit = Math.min(toInt(req.query.limit, 80), 200);
  query(res, `
    SELECT user_id, user_name, role, contact, fn_user_active_borrow_count(user_id) AS active_count
    FROM users
    WHERE (:q = '' OR user_name LIKE :keyword OR contact LIKE :keyword OR CAST(user_id AS CHAR) = :q)
    ORDER BY user_id DESC
    LIMIT ${limit}
  `, { q, keyword: like(q) });
});

app.post("/api/users", (req, res) => {
  const { user_name, role, contact } = req.body;
  execute(res, "INSERT INTO users (user_name, role, contact) VALUES (:user_name, :role, :contact)", {
    user_name,
    role: role || "Student",
    contact: contact || null
  });
});

app.put("/api/users/:id", (req, res) => {
  const { user_name, role, contact } = req.body;
  execute(res, "UPDATE users SET user_name = :user_name, role = :role, contact = :contact WHERE user_id = :id", {
    id: req.params.id,
    user_name,
    role: role || "Student",
    contact: contact || null
  });
});

app.delete("/api/users/:id", (req, res) => {
  execute(res, "DELETE FROM users WHERE user_id = :id", { id: req.params.id });
});

app.get("/api/equipments", (req, res) => {
  const q = String(req.query.q || "").trim();
  const status = String(req.query.status || "").trim();
  const category = String(req.query.category_id || "").trim();
  const room = String(req.query.room_id || "").trim();
  const limit = Math.min(toInt(req.query.limit, 100), 300);
  query(res, `
    SELECT
      e.equip_id, e.equip_name, e.category_id, c.category_name,
      e.room_id, r.room_name, e.status, e.price, e.purchase_date
    FROM equipments e
    JOIN categories c ON e.category_id = c.category_id
    JOIN labrooms r ON e.room_id = r.room_id
    WHERE (:q = '' OR e.equip_name LIKE :keyword OR CAST(e.equip_id AS CHAR) = :q)
      AND (:status = '' OR e.status = :status)
      AND (:category = '' OR e.category_id = :category)
      AND (:room = '' OR e.room_id = :room)
    ORDER BY e.equip_id DESC
    LIMIT ${limit}
  `, { q, keyword: like(q), status, category, room });
});

app.post("/api/equipments", (req, res) => {
  const { equip_name, category_id, room_id, status, price, purchase_date } = req.body;
  execute(res, `
    INSERT INTO equipments (equip_name, category_id, room_id, status, price, purchase_date)
    VALUES (:equip_name, :category_id, :room_id, :status, :price, :purchase_date)
  `, {
    equip_name,
    category_id,
    room_id,
    status: status || "Available",
    price: price || null,
    purchase_date: purchase_date || null
  });
});

app.put("/api/equipments/:id", (req, res) => {
  const { equip_name, category_id, room_id, status, price, purchase_date } = req.body;
  execute(res, `
    UPDATE equipments
    SET equip_name = :equip_name, category_id = :category_id, room_id = :room_id,
        status = :status, price = :price, purchase_date = :purchase_date
    WHERE equip_id = :id
  `, {
    id: req.params.id,
    equip_name,
    category_id,
    room_id,
    status: status || "Available",
    price: price || null,
    purchase_date: purchase_date || null
  });
});

app.delete("/api/equipments/:id", (req, res) => {
  execute(res, "DELETE FROM equipments WHERE equip_id = :id", { id: req.params.id });
});

app.get("/api/records", (req, res) => {
  const q = String(req.query.q || "").trim();
  const active = String(req.query.active || "").trim();
  const limit = Math.min(toInt(req.query.limit, 100), 300);
  query(res, `
    SELECT
      b.record_id, b.equip_id, e.equip_name, b.user_id, u.user_name,
      b.borrow_date, b.plan_return_date, b.actual_return_date,
      CASE
        WHEN b.actual_return_date IS NULL AND b.plan_return_date < CURRENT_DATE() THEN 'Overdue'
        WHEN b.actual_return_date IS NULL THEN 'Active'
        ELSE 'Returned'
      END AS record_status
    FROM borrowrecords b
    JOIN equipments e ON b.equip_id = e.equip_id
    JOIN users u ON b.user_id = u.user_id
    WHERE (:q = '' OR e.equip_name LIKE :keyword OR u.user_name LIKE :keyword OR CAST(b.record_id AS CHAR) = :q)
      AND (:active = '' OR (:active = '1' AND b.actual_return_date IS NULL) OR (:active = '0' AND b.actual_return_date IS NOT NULL))
    ORDER BY b.record_id DESC
    LIMIT ${limit}
  `, { q, keyword: like(q), active });
});

app.post("/api/borrow", async (req, res) => {
  const { equip_id, user_id, borrow_date, days } = req.body;
  try {
    const [sets] = await pool.query("CALL sp_borrow_equipment(:equip_id, :user_id, :borrow_date, :days)", {
      equip_id,
      user_id,
      borrow_date,
      days
    });
    res.json({ ok: true, row: sets?.[0]?.[0] || null });
  } catch (error) {
    sendError(res, error);
  }
});

app.post("/api/return", async (req, res) => {
  const { record_id, return_date } = req.body;
  try {
    const [sets] = await pool.query("CALL sp_return_equipment(:record_id, :return_date)", {
      record_id,
      return_date
    });
    res.json({ ok: true, row: sets?.[0]?.[0] || null });
  } catch (error) {
    sendError(res, error);
  }
});

app.get("/api/users/:id/active-count", async (req, res) => {
  query(res, "SELECT fn_user_active_borrow_count(:id) AS active_count", { id: req.params.id });
});

app.listen(port, () => {
  console.log(`API server listening on http://localhost:${port}`);
});
