# Member 4 操作指南（Supabase 后端 + Web Admin）

> 你的部分 = **Supabase（数据库 / REST API / 图片存储 / 安全规则）+ Flutter Web 管理后台**。
> "后端"不需要自己写服务器：Supabase 自动把数据库表变成 REST API，你负责**建表 + 写安全规则**。
> Android Studio 用来写和运行 Flutter 代码（Web Admin 在 Chrome 里跑）。

---

## 项目里属于你的文件

```
supabase/
  migrations/
    20261113000001_init_schema.sql          ← 建表 + 自动建 profile + is_admin()
    20261113000002_rls_policies.sql         ← 权限（谁能看/改什么）
    20261113000003_private_photo_storage.sql← 私有图片桶 + 权限
  tests/rls_security_tests.sql              ← 19 个权限测试（截图当证据）
  seed/make_admin.sql                       ← 把某个账号升为 admin
lib/
  core/supabase_config.dart                 ← 读取 URL / key（不写死在代码里）
  data/models/…                             ← 共享数据模型（给全组用）
  data/repositories/…                       ← 共享 Repository（全组统一调用）
  admin/…                                   ← Web Admin 页面
  main_admin.dart                           ← Web Admin 入口
docs/backend/API_CONTRACT.md                ← 发给组员的"数据库合约"
```

---

## 第 1 步：建 Supabase 项目（全组只用 1 个！）
1. 去 https://supabase.com → 登录 → **New project**（Free plan）。Region 选 **Singapore**（离马来西亚近）。
2. 数据库密码存好（不要发到群里/GitHub）。
3. 进入 **Project Settings → API Keys**，记下：
   - **Project URL**（`https://xxxx.supabase.co`）
   - **Publishable key**（或旧版的 `anon` key）← 这个可以放 App 里
   - ⚠️ **secret / service_role key 绝对不要放进 Flutter、不要上传 GitHub**
4. **Project Settings → Team** 邀请组员（这样大家用同一个项目）。

## 第 2 步：执行 migration（建表 + 权限）
1. 左边 **SQL Editor → New query**。
2. 打开 `20261113000001_init_schema.sql`，**全部复制**粘贴 → **Run**。看到 `Success` 即可。
3. 同样执行 `…000002_rls_policies.sql`，再执行 `…000003_private_photo_storage.sql`。**顺序不能乱。**
4. 检查：
   - **Table Editor** 里有 `profiles` 和 `incident_reports`，两个表都显示 **RLS enabled**。
   - **Storage** 里有 `report-photos`，标记为 **Private**。

> 老师/组员问 "这些 SQL 做什么？"——每个文件开头都有英文注释解释，你可以直接引用到 Technical Report。

## 第 3 步：跑安全测试（截图当证据，11/16 截止）
1. SQL Editor → New query → 粘贴 `supabase/tests/rls_security_tests.sql` → Run。
2. 结果表 19 行应全部是 **PASS**。截图 → 放进 PR 和 ITPM 证据。
3. 测试会自己建 3 个假账号，跑完自动删除，不会弄脏共享数据库。
4. 如果有 FAIL，把那一行发给我，我们一起看。

## 第 4 步：建一个 admin 账号
1. **Authentication → Users → Add user → Create new user**（勾选 Auto Confirm），例如你的 staff 测试邮箱。
2. 打开 `supabase/seed/make_admin.sql`，把邮箱改成刚才那个 → Run。
3. 最后的结果表里那个邮箱的 role 应该是 `admin`。
4. 顺便再建一个普通账号（student）用来测试"学生不能进后台"。

## 第 5 步：在 Android Studio 打开项目
1. Android Studio 需要装 **Flutter** 和 **Dart** 插件（Settings → Plugins）。
2. **File → Open** → 选 `uts_campus_safety` 文件夹。
3. 把 `env.example.json` **复制一份**命名为 `env.json`，填入第 1 步的 URL 和 publishable key。
   （`env.json` 已在 `.gitignore`，不会被上传。）
4. 终端运行 `flutter pub get`（或点 Android Studio 顶部的 "Pub get"）。

## 第 6 步：运行 Web Admin
- 顶部运行配置下拉框选 **"Web Admin (Chrome)"** → 点 ▶。
- 或者在终端：
  ```
  flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env.json
  ```
- 用 admin 账号登录 → 看到报告列表。
- 用 student 账号登录 → 应显示 **Access denied**（这也是一个测试截图）。

### 造几条测试数据（还没有学生 App 时）
在 SQL Editor 运行（把邮箱换成你的 student 测试账号）：
```sql
insert into public.incident_reports (reporter_id, category, description, latitude, longitude)
select id, 'lighting', 'Street light broken near Block C', 2.3150, 111.8300
from auth.users where email = 'student.test@example.com';
```

## 第 7 步：演示功能（11/27 列表+详情，12/6 改状态）
- 列表：顶部 3 张统计卡（Pending / In Progress / Resolved），点击可筛选。
- 详情：照片（私有图片用 1 小时有效的 signed URL 显示）、描述、坐标、地图链接。
- 改状态：选新状态 → Save status → 确认 → 成功提示。

## 第 8 步：GitHub
- 在组里的那个 repo 开自己的分支，例如 `feature/m4-supabase-backend`。
- **如果组 repo 已经有 Flutter 项目了**：只复制上面"属于你的文件"进去，再 `flutter pub add supabase_flutter`（先跟组员说一声，因为改了依赖）。
- PR 描述里附上：RLS 测试截图、admin 登录 / student 被拒截图、改状态前后截图。
- 提交前确认 `git status` 里**没有** `env.json`。

## 给组员的东西（马上发）
- `docs/backend/API_CONTRACT.md`：表结构、允许的值、权限表、每个人要调用哪个方法。
- 原本 11/7 就应该分享，现在补上，并在 ITPM 里记录成 "planned vs actual" 的一条延迟（真实证据）。

## 常见问题
| 现象 | 原因 / 解决 |
|---|---|
| 登录后显示 Access denied | 该账号不是 admin → 跑 `make_admin.sql` |
| 列表是空的 | 还没有报告 → 用上面的 SQL 造测试数据 |
| `permission denied for table` | 正常的安全拦截（例如学生想改 status）|
| 照片显示 "Photo unavailable" | `photo_path` 指向的文件不存在，或不在上传者自己的文件夹 |
| 启动显示 "Supabase is not configured" | 没有 `env.json`，或运行时没加 `--dart-define-from-file=env.json` |
| `flutter build web` 报 `IconTreeShaker.subsetFont` 错误 | 本机字体裁剪工具的问题，加 `--no-tree-shake-icons` 即可：`flutter build web --no-tree-shake-icons -t lib/main_admin.dart --dart-define-from-file=env.json` |
