from pathlib import Path
from xml.sax.saxutils import escape
from zipfile import ZIP_DEFLATED, ZipFile


BASE_DIR = Path(__file__).resolve().parent
OUTPUT_PATH = BASE_DIR / "实验室设备管理系统_个人报告_2_3_6.docx"


REPORT_BLOCKS = [
    ("title", "数据库大作业个人报告"),
    ("center", "题目：实验室设备管理系统（本人负责内容：2、3、6）"),
    ("center", "数据库：MySQL 8.0 / InnoDB"),
    ("heading1", "一、本人负责内容"),
    ("p", "根据小组分工，本人主要负责三部分内容：第一，设计并实现至少三个触发器；第二，设计并实现至少两个带参存储过程或函数；第三，使用规范化理论说明数据库模式从原始业务单据到第三范式的建立过程。"),
    ("heading1", "二、系统业务背景"),
    ("p", "本系统以实验室设备管理为背景，围绕设备类别、实验室房间、用户、设备台账和借用记录建立数据库。另一位同学已经完成了五张基础表、游标过程和索引性能分析。本人在此基础上继续完成借还业务自动维护、过程封装和规范化说明。"),
    ("heading1", "三、触发器设计"),
    ("p", "本人共设计三个触发器，均建立在 borrowrecords 表上，用于保证设备借还业务的一致性。trg_borrowrecords_before_insert 用于插入前校验日期、设备状态和是否重复借出；trg_borrowrecords_after_insert 用于借用记录插入后自动把设备状态改为 Borrowed；trg_borrowrecords_after_update 用于归还后自动把设备状态恢复为 Available。"),
    ("heading2", "3.1 插入前校验触发器"),
    ("p", "trg_borrowrecords_before_insert 在新增借用记录前执行，主要检查计划归还日期不能早于借用日期，实际归还日期不能早于借用日期，维修或报废设备不能借出，并且同一设备不能同时存在多条未归还记录。"),
    ("heading2", "3.2 插入后状态触发器"),
    ("p", "trg_borrowrecords_after_insert 在新增未归还借用记录后执行，将对应设备状态自动更新为 Borrowed。该触发器减少了应用层手动维护状态的工作量，也避免了借用记录与设备台账状态不一致。"),
    ("heading2", "3.3 更新后归还触发器"),
    ("p", "trg_borrowrecords_after_update 在借用记录更新后执行。当 actual_return_date 由空变为非空时，说明设备完成归还。触发器会检查该设备是否还有其他未归还记录，如果没有，则将设备状态恢复为 Available。"),
    ("heading1", "四、带参存储过程和函数"),
    ("p", "本人设计了两个带参存储过程和一个带参函数。sp_borrow_equipment(p_equip_id, p_user_id, p_borrow_date, p_days) 用于封装设备借用操作；sp_return_equipment(p_record_id, p_return_date) 用于封装设备归还操作；fn_user_active_borrow_count(p_user_id) 用于统计指定用户当前未归还设备数量。"),
    ("heading2", "4.1 借用设备过程"),
    ("code", "CALL sp_borrow_equipment(设备编号, 用户编号, CURRENT_DATE(), 借用天数);"),
    ("p", "该过程先检查设备编号、用户编号、借用日期和借用天数是否合法，再检查设备和用户是否存在，最后插入借用记录。插入动作会自动触发前后两个触发器，因此过程本身不需要重复编写全部状态维护逻辑。"),
    ("heading2", "4.2 归还设备过程"),
    ("code", "CALL sp_return_equipment(借用记录编号, CURRENT_DATE());"),
    ("p", "该过程根据借用记录编号查询原始记录，检查记录是否存在、是否已经归还以及归还日期是否合法，然后更新 actual_return_date。更新完成后，归还触发器负责自动恢复设备状态。"),
    ("heading2", "4.3 用户未归还数量函数"),
    ("code", "SELECT fn_user_active_borrow_count(用户编号) AS active_count;"),
    ("p", "该函数根据传入用户编号统计 actual_return_date 为空的借用记录数量，可用于个人借用情况查看、管理员风险提醒和演示验证。"),
    ("heading1", "五、规范化理论建模过程"),
    ("p", "如果直接使用一张大表保存实验室设备借用登记，会包含设备信息、类别信息、房间信息、用户信息和借还日期。这种设计会造成类别、房间、用户信息重复存储，并引发更新异常、插入异常和删除异常。"),
    ("p", "根据业务规则可以得到主要函数依赖：category_id 决定类别名称和说明，room_id 决定房间名称、位置和管理员，user_id 决定用户姓名、角色和联系方式，equip_id 决定设备名称、类别、房间、状态、价格和购置日期，record_id 决定设备、用户和借还日期。"),
    ("p", "第一范式要求字段原子化，因此系统将房间、用户、设备和借还日期拆分成不可再分的字段。第二范式要求消除部分依赖，因此将设备类别、房间、用户、设备和借用记录拆成独立表。第三范式要求消除传递依赖，因此在设备表中只保存 category_id 和 room_id，在借用记录表中只保存 equip_id 和 user_id，不重复保存类别名、房间名和用户联系方式。"),
    ("p", "最终关系模式包括 categories(category_id, category_name, description)、labrooms(room_id, room_name, location, admin_name)、users(user_id, user_name, role, contact)、equipments(equip_id, equip_name, category_id, room_id, status, price, purchase_date) 和 borrowrecords(record_id, equip_id, user_id, borrow_date, plan_return_date, actual_return_date)。"),
    ("heading1", "六、测试与验证"),
    ("p", "在阿里云 MySQL RDS 的 <database_name> 数据库中，已执行 Q236/01_triggers.sql 和 Q236/02_parameterized_routines.sql 创建数据库对象，并通过 Q236/04_demo_and_test.sql 进行演示验证。演示流程为自动选择一台可用设备，调用借用过程，查看设备状态变为 Borrowed，再调用归还过程，查看设备状态恢复为 Available。"),
    ("bullet", "借用过程可成功新增借用记录。"),
    ("bullet", "插入后触发器可自动维护设备状态。"),
    ("bullet", "归还过程可成功写入实际归还日期。"),
    ("bullet", "更新后触发器可自动恢复设备状态。"),
    ("bullet", "带参函数可统计用户当前未归还设备数量。"),
    ("heading1", "七、云数据库演示结果"),
    ("p", "本次云数据库演示自动选择用户 1 和设备 1，调用 sp_borrow_equipment 后新增借用记录 4096。借用后设备状态为 Borrowed，用户未归还数量由 0 变为 1。随后调用 sp_return_equipment 归还该记录，设备状态恢复为 Available，用户未归还数量由 1 回到 0。"),
    ("heading1", "八、结论"),
    ("p", "本人完成了实验室设备管理系统中三个触发器、两个带参存储过程、一个带参函数以及规范化理论建模说明。实现后，数据库不仅能够保存借还数据，还能主动维护关键业务一致性，满足课程设计对触发器、带参过程或函数和规范化分析的要求。"),
    ("heading1", "附录：关键 SQL 对象"),
    ("bullet", "触发器：trg_borrowrecords_before_insert"),
    ("bullet", "触发器：trg_borrowrecords_after_insert"),
    ("bullet", "触发器：trg_borrowrecords_after_update"),
    ("bullet", "存储过程：sp_borrow_equipment"),
    ("bullet", "存储过程：sp_return_equipment"),
    ("bullet", "函数：fn_user_active_borrow_count"),
]


def paragraph_xml(kind, text):
    text = escape(text)
    justify = ""
    indent = ""
    size = "24"
    font = "宋体"
    bold_open = ""
    bold_close = ""

    if kind in {"title", "center"}:
        justify = '<w:jc w:val="center"/>'
    if kind == "title":
        size = "36"
        font = "黑体"
        bold_open = "<w:b/>"
    elif kind == "heading1":
        size = "28"
        font = "黑体"
        bold_open = "<w:b/>"
    elif kind == "heading2":
        font = "黑体"
        bold_open = "<w:b/>"
    elif kind == "p":
        indent = '<w:ind w:firstLine="480"/>'
    elif kind == "bullet":
        indent = '<w:ind w:left="360"/>'
        text = "• " + text
    elif kind == "code":
        font = "Consolas"
        size = "21"
        indent = '<w:ind w:left="480"/>'

    return f"""
    <w:p>
      <w:pPr>{justify}{indent}</w:pPr>
      <w:r>
        <w:rPr>
          {bold_open}
          <w:rFonts w:ascii="{font}" w:hAnsi="{font}" w:eastAsia="{font}"/>
          <w:sz w:val="{size}"/>
        </w:rPr>
        <w:t>{text}</w:t>
      </w:r>
    </w:p>
    """


def build_document_xml():
    body = "\n".join(paragraph_xml(kind, text) for kind, text in REPORT_BLOCKS)
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    {body}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/>
    </w:sectPr>
  </w:body>
</w:document>
"""


def write_docx(path):
    content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
"""
    rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"""
    document_xml = build_document_xml()

    with ZipFile(path, "w", ZIP_DEFLATED) as docx:
        docx.writestr("[Content_Types].xml", content_types)
        docx.writestr("_rels/.rels", rels)
        docx.writestr("word/document.xml", document_xml)


if __name__ == "__main__":
    write_docx(OUTPUT_PATH)
    print(OUTPUT_PATH)
