import React, { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  Activity,
  Boxes,
  Building2,
  CheckCircle2,
  Database,
  Gauge,
  History,
  Plus,
  RefreshCw,
  RotateCcw,
  Save,
  Search,
  Trash2,
  UserRound,
  Wrench
} from "lucide-react";
import "./styles.css";

const emptyEquipment = {
  equip_name: "",
  category_id: "",
  room_id: "",
  status: "Available",
  price: "",
  purchase_date: ""
};

const emptyUser = { user_name: "", role: "Student", contact: "" };
const emptyRoom = { room_name: "", location: "", admin_name: "" };
const emptyCategory = { category_name: "", description: "" };

const statusLabels = {
  Available: "可用",
  Borrowed: "借出",
  Maintenance: "维修",
  Scrapped: "报废",
  Active: "未归还",
  Returned: "已归还",
  Overdue: "逾期"
};

async function api(path, options = {}) {
  const response = await fetch(`/api${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || "请求失败");
  return data;
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function App() {
  const [activeTab, setActiveTab] = useState("dashboard");
  const [stats, setStats] = useState(null);
  const [health, setHealth] = useState(null);
  const [categories, setCategories] = useState([]);
  const [rooms, setRooms] = useState([]);
  const [users, setUsers] = useState([]);
  const [equipments, setEquipments] = useState([]);
  const [records, setRecords] = useState([]);
  const [notice, setNotice] = useState(null);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    equipmentQ: "",
    equipmentStatus: "",
    categoryId: "",
    roomId: "",
    userQ: "",
    recordQ: "",
    recordActive: ""
  });
  const [equipmentForm, setEquipmentForm] = useState(emptyEquipment);
  const [userForm, setUserForm] = useState(emptyUser);
  const [roomForm, setRoomForm] = useState(emptyRoom);
  const [categoryForm, setCategoryForm] = useState(emptyCategory);
  const [borrowForm, setBorrowForm] = useState({
    equip_id: "",
    user_id: "",
    borrow_date: today(),
    days: 7
  });
  const [returnForm, setReturnForm] = useState({ record_id: "", return_date: today() });
  const [editing, setEditing] = useState({ type: "", id: null });

  const tabs = useMemo(
    () => [
      { id: "dashboard", label: "总览", icon: Gauge },
      { id: "equipment", label: "设备", icon: Boxes },
      { id: "borrow", label: "借还", icon: RotateCcw },
      { id: "users", label: "用户", icon: UserRound },
      { id: "rooms", label: "房间", icon: Building2 },
      { id: "categories", label: "类别", icon: Database },
      { id: "records", label: "记录", icon: History }
    ],
    []
  );

  function toast(message, kind = "success") {
    setNotice({ message, kind });
    window.clearTimeout(window.__noticeTimer);
    window.__noticeTimer = window.setTimeout(() => setNotice(null), 3600);
  }

  async function loadBase() {
    const [categoryRows, roomRows] = await Promise.all([api("/categories"), api("/rooms")]);
    setCategories(categoryRows);
    setRooms(roomRows);
  }

  async function loadStats() {
    const [statsData, healthData] = await Promise.all([api("/stats"), api("/health")]);
    setStats(statsData);
    setHealth(healthData);
  }

  async function loadUsers() {
    const rows = await api(`/users?q=${encodeURIComponent(filters.userQ)}`);
    setUsers(rows);
  }

  async function loadEquipments() {
    const params = new URLSearchParams({
      q: filters.equipmentQ,
      status: filters.equipmentStatus,
      category_id: filters.categoryId,
      room_id: filters.roomId
    });
    setEquipments(await api(`/equipments?${params}`));
  }

  async function loadRecords() {
    const params = new URLSearchParams({
      q: filters.recordQ,
      active: filters.recordActive
    });
    setRecords(await api(`/records?${params}`));
  }

  async function refreshAll() {
    setLoading(true);
    try {
      await loadBase();
      await Promise.all([loadStats(), loadUsers(), loadEquipments(), loadRecords()]);
    } catch (error) {
      toast(error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    refreshAll();
  }, []);

  useEffect(() => {
    loadEquipments().catch((error) => toast(error.message, "error"));
  }, [filters.equipmentStatus, filters.categoryId, filters.roomId]);

  async function saveEquipment(event) {
    event.preventDefault();
    const path = editing.type === "equipment" ? `/equipments/${editing.id}` : "/equipments";
    const method = editing.type === "equipment" ? "PUT" : "POST";
    await mutate(path, method, equipmentForm, "设备信息已保存");
    setEquipmentForm(emptyEquipment);
    setEditing({ type: "", id: null });
  }

  async function saveUser(event) {
    event.preventDefault();
    const path = editing.type === "user" ? `/users/${editing.id}` : "/users";
    const method = editing.type === "user" ? "PUT" : "POST";
    await mutate(path, method, userForm, "用户信息已保存");
    setUserForm(emptyUser);
    setEditing({ type: "", id: null });
  }

  async function saveRoom(event) {
    event.preventDefault();
    const path = editing.type === "room" ? `/rooms/${editing.id}` : "/rooms";
    const method = editing.type === "room" ? "PUT" : "POST";
    await mutate(path, method, roomForm, "实验室信息已保存");
    setRoomForm(emptyRoom);
    setEditing({ type: "", id: null });
  }

  async function saveCategory(event) {
    event.preventDefault();
    const path = editing.type === "category" ? `/categories/${editing.id}` : "/categories";
    const method = editing.type === "category" ? "PUT" : "POST";
    await mutate(path, method, categoryForm, "类别信息已保存");
    setCategoryForm(emptyCategory);
    setEditing({ type: "", id: null });
  }

  async function mutate(path, method, body, message) {
    setLoading(true);
    try {
      await api(path, { method, body: JSON.stringify(body) });
      toast(message);
      await refreshAll();
    } catch (error) {
      toast(error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  async function removeItem(type, id) {
    const names = {
      equipment: "equipments",
      user: "users",
      room: "rooms",
      category: "categories"
    };
    await mutate(`/${names[type]}/${id}`, "DELETE", {}, "已删除");
  }

  async function borrowEquipment(event) {
    event.preventDefault();
    await mutate("/borrow", "POST", borrowForm, "借用成功");
    setBorrowForm({ equip_id: "", user_id: "", borrow_date: today(), days: 7 });
  }

  async function returnEquipment(event) {
    event.preventDefault();
    await mutate("/return", "POST", returnForm, "归还成功");
    setReturnForm({ record_id: "", return_date: today() });
  }

  function searchButton(onClick) {
    return (
      <button className="icon-button" type="button" onClick={onClick} title="查询">
        <Search size={18} />
      </button>
    );
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark"><Wrench size={22} /></div>
          <div>
            <h1>实验室设备管理系统</h1>
            <p>Lab Equipment DB</p>
          </div>
        </div>
        <nav>
          {tabs.map((tab) => {
            const Icon = tab.icon;
            return (
              <button
                key={tab.id}
                className={activeTab === tab.id ? "active" : ""}
                onClick={() => setActiveTab(tab.id)}
                title={tab.label}
              >
                <Icon size={18} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>
      </aside>

      <main>
        <header className="topbar">
          <div>
            <p className="eyebrow">MySQL 8.0 / InnoDB</p>
            <h2>{tabs.find((tab) => tab.id === activeTab)?.label}</h2>
          </div>
          <div className="top-actions">
            {health && <span className="connection"><CheckCircle2 size={16} /> {health.database_name}</span>}
            <button className="secondary" onClick={refreshAll} disabled={loading}>
              <RefreshCw size={17} className={loading ? "spin" : ""} />
              刷新
            </button>
          </div>
        </header>

        {notice && <div className={`notice ${notice.kind}`}>{notice.message}</div>}

        {activeTab === "dashboard" && (
          <section className="stack">
            <div className="metric-grid">
              <Metric icon={Boxes} label="设备总数" value={stats?.total} tone="green" />
              <Metric icon={CheckCircle2} label="可用设备" value={stats?.available} tone="blue" />
              <Metric icon={Activity} label="借出设备" value={stats?.borrowed} tone="orange" />
              <Metric icon={History} label="未归还记录" value={stats?.active_records} tone="red" />
              <Metric icon={UserRound} label="用户数量" value={stats?.total_users} tone="violet" />
              <Metric icon={Building2} label="实验室数量" value={stats?.total_rooms} tone="teal" />
            </div>
            <div className="split">
              <Panel title="设备状态">
                <div className="status-bars">
                  {["available", "borrowed", "maintenance", "scrapped"].map((key) => (
                    <StatusBar key={key} name={key} count={Number(stats?.[key] || 0)} total={Number(stats?.total || 1)} />
                  ))}
                </div>
              </Panel>
              <Panel title="近期借用记录">
                <RecordTable rows={records.slice(0, 8)} compact />
              </Panel>
            </div>
          </section>
        )}

        {activeTab === "equipment" && (
          <section className="stack">
            <Panel title={editing.type === "equipment" ? "编辑设备" : "新增设备"}>
              <form className="form-grid" onSubmit={saveEquipment}>
                <Field label="设备名称" value={equipmentForm.equip_name} onChange={(v) => setEquipmentForm({ ...equipmentForm, equip_name: v })} required />
                <Select label="类别" value={equipmentForm.category_id} onChange={(v) => setEquipmentForm({ ...equipmentForm, category_id: v })} options={categories.map((c) => [c.category_id, c.category_name])} required />
                <Select label="房间" value={equipmentForm.room_id} onChange={(v) => setEquipmentForm({ ...equipmentForm, room_id: v })} options={rooms.map((r) => [r.room_id, r.room_name])} required />
                <Select label="状态" value={equipmentForm.status} onChange={(v) => setEquipmentForm({ ...equipmentForm, status: v })} options={["Available", "Borrowed", "Maintenance", "Scrapped"].map((s) => [s, statusLabels[s]])} />
                <Field label="价格" type="number" value={equipmentForm.price} onChange={(v) => setEquipmentForm({ ...equipmentForm, price: v })} />
                <Field label="购置日期" type="date" value={equipmentForm.purchase_date || ""} onChange={(v) => setEquipmentForm({ ...equipmentForm, purchase_date: v })} />
                <button className="primary"><Save size={17} />保存</button>
              </form>
            </Panel>
            <Panel title="设备台账">
              <Toolbar>
                <Field compact placeholder="设备编号或名称" value={filters.equipmentQ} onChange={(v) => setFilters({ ...filters, equipmentQ: v })} />
                <Select compact value={filters.equipmentStatus} onChange={(v) => setFilters({ ...filters, equipmentStatus: v })} options={[["", "全部状态"], ...["Available", "Borrowed", "Maintenance", "Scrapped"].map((s) => [s, statusLabels[s]])]} />
                <Select compact value={filters.categoryId} onChange={(v) => setFilters({ ...filters, categoryId: v })} options={[["", "全部类别"], ...categories.map((c) => [c.category_id, c.category_name])]} />
                <Select compact value={filters.roomId} onChange={(v) => setFilters({ ...filters, roomId: v })} options={[["", "全部房间"], ...rooms.map((r) => [r.room_id, r.room_name])]} />
                {searchButton(loadEquipments)}
              </Toolbar>
              <EquipmentTable rows={equipments} onEdit={(row) => {
                setEquipmentForm({ ...row, purchase_date: row.purchase_date || "" });
                setEditing({ type: "equipment", id: row.equip_id });
              }} onDelete={(id) => removeItem("equipment", id)} />
            </Panel>
          </section>
        )}

        {activeTab === "borrow" && (
          <section className="split">
            <Panel title="借用设备">
              <form className="form-grid single" onSubmit={borrowEquipment}>
                <Field label="设备编号" type="number" value={borrowForm.equip_id} onChange={(v) => setBorrowForm({ ...borrowForm, equip_id: v })} required />
                <Field label="用户编号" type="number" value={borrowForm.user_id} onChange={(v) => setBorrowForm({ ...borrowForm, user_id: v })} required />
                <Field label="借用日期" type="date" value={borrowForm.borrow_date} onChange={(v) => setBorrowForm({ ...borrowForm, borrow_date: v })} required />
                <Field label="借用天数" type="number" value={borrowForm.days} onChange={(v) => setBorrowForm({ ...borrowForm, days: v })} required />
                <button className="primary"><Plus size={17} />借出</button>
              </form>
            </Panel>
            <Panel title="归还设备">
              <form className="form-grid single" onSubmit={returnEquipment}>
                <Field label="借用记录编号" type="number" value={returnForm.record_id} onChange={(v) => setReturnForm({ ...returnForm, record_id: v })} required />
                <Field label="归还日期" type="date" value={returnForm.return_date} onChange={(v) => setReturnForm({ ...returnForm, return_date: v })} required />
                <button className="primary"><RotateCcw size={17} />归还</button>
              </form>
            </Panel>
            <Panel title="可用设备">
              <EquipmentTable rows={equipments.filter((row) => row.status === "Available").slice(0, 10)} onPick={(row) => setBorrowForm({ ...borrowForm, equip_id: row.equip_id })} compact />
            </Panel>
            <Panel title="未归还记录">
              <RecordTable rows={records.filter((row) => !row.actual_return_date).slice(0, 10)} onPick={(row) => setReturnForm({ ...returnForm, record_id: row.record_id })} compact />
            </Panel>
          </section>
        )}

        {activeTab === "users" && (
          <CrudSection
            title="用户"
            form={
              <form className="form-grid" onSubmit={saveUser}>
                <Field label="姓名" value={userForm.user_name} onChange={(v) => setUserForm({ ...userForm, user_name: v })} required />
                <Select label="角色" value={userForm.role} onChange={(v) => setUserForm({ ...userForm, role: v })} options={[["Student", "学生"], ["Teacher", "教师"], ["Staff", "职工"]]} />
                <Field label="联系方式" value={userForm.contact} onChange={(v) => setUserForm({ ...userForm, contact: v })} />
                <button className="primary"><Save size={17} />保存</button>
              </form>
            }
            toolbar={
              <Toolbar>
                <Field compact placeholder="用户编号、姓名或电话" value={filters.userQ} onChange={(v) => setFilters({ ...filters, userQ: v })} />
                {searchButton(loadUsers)}
              </Toolbar>
            }
          >
            <SimpleTable
              columns={["编号", "姓名", "角色", "联系方式", "未归还", "操作"]}
              rows={users.map((row) => [row.user_id, row.user_name, row.role, row.contact, row.active_count, actions("user", row, row.user_id)])}
            />
          </CrudSection>
        )}

        {activeTab === "rooms" && (
          <CrudSection title="实验室" form={
            <form className="form-grid" onSubmit={saveRoom}>
              <Field label="房间名称" value={roomForm.room_name} onChange={(v) => setRoomForm({ ...roomForm, room_name: v })} required />
              <Field label="位置" value={roomForm.location} onChange={(v) => setRoomForm({ ...roomForm, location: v })} />
              <Field label="管理员" value={roomForm.admin_name} onChange={(v) => setRoomForm({ ...roomForm, admin_name: v })} />
              <button className="primary"><Save size={17} />保存</button>
            </form>
          }>
            <SimpleTable columns={["编号", "名称", "位置", "管理员", "操作"]} rows={rooms.map((row) => [row.room_id, row.room_name, row.location, row.admin_name, actions("room", row, row.room_id)])} />
          </CrudSection>
        )}

        {activeTab === "categories" && (
          <CrudSection title="设备类别" form={
            <form className="form-grid" onSubmit={saveCategory}>
              <Field label="类别名称" value={categoryForm.category_name} onChange={(v) => setCategoryForm({ ...categoryForm, category_name: v })} required />
              <Field label="说明" value={categoryForm.description} onChange={(v) => setCategoryForm({ ...categoryForm, description: v })} />
              <button className="primary"><Save size={17} />保存</button>
            </form>
          }>
            <SimpleTable columns={["编号", "名称", "说明", "操作"]} rows={categories.map((row) => [row.category_id, row.category_name, row.description, actions("category", row, row.category_id)])} />
          </CrudSection>
        )}

        {activeTab === "records" && (
          <Panel title="借用记录">
            <Toolbar>
              <Field compact placeholder="记录编号、设备或用户" value={filters.recordQ} onChange={(v) => setFilters({ ...filters, recordQ: v })} />
              <Select compact value={filters.recordActive} onChange={(v) => setFilters({ ...filters, recordActive: v })} options={[["", "全部记录"], ["1", "未归还"], ["0", "已归还"]]} />
              {searchButton(loadRecords)}
            </Toolbar>
            <RecordTable rows={records} onPick={(row) => setReturnForm({ ...returnForm, record_id: row.record_id })} />
          </Panel>
        )}
      </main>
    </div>
  );

  function actions(type, row, id) {
    return (
      <div className="row-actions">
        <button className="icon-button" title="编辑" onClick={() => {
          if (type === "user") setUserForm(row);
          if (type === "room") setRoomForm(row);
          if (type === "category") setCategoryForm(row);
          setEditing({ type, id });
        }}><Save size={16} /></button>
        <button className="icon-button danger" title="删除" onClick={() => removeItem(type, id)}><Trash2 size={16} /></button>
      </div>
    );
  }
}

function Metric({ icon: Icon, label, value, tone }) {
  return (
    <div className={`metric ${tone}`}>
      <Icon size={22} />
      <span>{label}</span>
      <strong>{value ?? "--"}</strong>
    </div>
  );
}

function Panel({ title, children }) {
  return (
    <section className="panel">
      <h3>{title}</h3>
      {children}
    </section>
  );
}

function Toolbar({ children }) {
  return <div className="toolbar">{children}</div>;
}

function CrudSection({ title, form, toolbar, children }) {
  return (
    <section className="stack">
      <Panel title={`新增/编辑${title}`}>{form}</Panel>
      <Panel title={`${title}列表`}>
        {toolbar}
        {children}
      </Panel>
    </section>
  );
}

function Field({ label, compact, value, onChange, ...props }) {
  return (
    <label className={compact ? "field compact" : "field"}>
      {label && <span>{label}</span>}
      <input value={value} onChange={(event) => onChange(event.target.value)} {...props} />
    </label>
  );
}

function Select({ label, compact, value, onChange, options, ...props }) {
  return (
    <label className={compact ? "field compact" : "field"}>
      {label && <span>{label}</span>}
      <select value={value} onChange={(event) => onChange(event.target.value)} {...props}>
        {options.map(([optionValue, optionLabel]) => (
          <option key={optionValue} value={optionValue}>{optionLabel}</option>
        ))}
      </select>
    </label>
  );
}

function StatusBar({ name, count, total }) {
  const width = `${Math.round((count / total) * 100)}%`;
  return (
    <div className="status-row">
      <div><span>{statusLabels[name[0].toUpperCase() + name.slice(1)]}</span><b>{count}</b></div>
      <i><em style={{ width }} /></i>
    </div>
  );
}

function StatusPill({ value }) {
  return <span className={`pill ${value}`}>{statusLabels[value] || value}</span>;
}

function EquipmentTable({ rows, onEdit, onDelete, onPick, compact }) {
  return (
    <SimpleTable
      columns={compact ? ["编号", "设备", "房间", "操作"] : ["编号", "设备", "类别", "房间", "状态", "价格", "购置日期", "操作"]}
      rows={rows.map((row) => compact ? [
        row.equip_id,
        row.equip_name,
        row.room_name,
        <button className="small" onClick={() => onPick?.(row)}>选择</button>
      ] : [
        row.equip_id,
        row.equip_name,
        row.category_name,
        row.room_name,
        <StatusPill value={row.status} />,
        row.price,
        row.purchase_date,
        <div className="row-actions">
          <button className="icon-button" title="编辑" onClick={() => onEdit?.(row)}><Save size={16} /></button>
          <button className="icon-button danger" title="删除" onClick={() => onDelete?.(row.equip_id)}><Trash2 size={16} /></button>
        </div>
      ])}
    />
  );
}

function RecordTable({ rows, onPick, compact }) {
  return (
    <SimpleTable
      columns={compact ? ["编号", "设备", "用户", "状态", "操作"] : ["编号", "设备", "用户", "借用日期", "计划归还", "实际归还", "状态", "操作"]}
      rows={rows.map((row) => compact ? [
        row.record_id,
        row.equip_name,
        row.user_name,
        <StatusPill value={row.record_status} />,
        <button className="small" onClick={() => onPick?.(row)}>选择</button>
      ] : [
        row.record_id,
        row.equip_name,
        row.user_name,
        row.borrow_date,
        row.plan_return_date,
        row.actual_return_date || "-",
        <StatusPill value={row.record_status} />,
        <button className="small" onClick={() => onPick?.(row)}>选择</button>
      ])}
    />
  );
}

function SimpleTable({ columns, rows }) {
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>{columns.map((column) => <th key={column}>{column}</th>)}</tr>
        </thead>
        <tbody>
          {rows.length === 0 && <tr><td colSpan={columns.length} className="empty">暂无数据</td></tr>}
          {rows.map((row, index) => (
            <tr key={index}>{row.map((cell, cellIndex) => <td key={cellIndex}>{cell}</td>)}</tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

createRoot(document.getElementById("root")).render(<App />);
