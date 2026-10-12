# Inspect for EllesmereUI

魔兽世界正式服装备观察插件，支持装等、宝石、附魔、耐久度、属性统计和按专精提供的装备推荐，可使用 EllesmereUI 样式。

A World of Warcraft Retail equipment inspection addon with item levels, gems, enchants, durability, statistics and specialization-based recommendations. EllesmereUI styling is optional.

## 安装 / Installation

从 [Releases](https://github.com/zhufei1000/InspectForEllesmereUI/releases/latest) 下载 InspectForEllesmereUI_版本号.zip，将其中的 InspectForEllesmereUI 文件夹解压到 World of Warcraft/_retail_/Interface/AddOns/，然后重新启动游戏。推荐数据库已包含在 GearData 中。

Download the addon ZIP from Releases, extract its InspectForEllesmereUI folder into _retail_/Interface/AddOns/, and restart the game. The recommendation database is bundled; EllesmereUI is optional.

- 设置命令 / Settings: `/ifeui` 或 `/inspectforellesmereui`
- 正式服接口 / Retail interfaces: `120100`, `120007`
- 存档变量 / SavedVariables: `InspectForEllesmereUIDB`, `InspectForEllesmereUICharacterDB`
- 侧栏标记：绿色 BIS / TOP1–TOP3，灰色 N/R；附魔星号绿色表示符合推荐、红色表示缺失或不同、黄色表示无法判断。
- 鼠标提示中的职业专精功能已移除。

## 本地化 / Localization

插件文字支持英文、简体中文、繁体中文；俄语设置提供部分翻译，其他语言回退英文。物品名称按 ID 从游戏客户端获取，装备排名和附魔判断不依赖翻译。自动测试覆盖 11 种客户端语言及原生/EUI 两种样式。[详细检查报告](docs/LOCALIZATION_AUDIT.md)。

## 开发与检查 / Development

```sh
python -m pip install -r tests/requirements.txt
python tests/run_recommendation_tests.py --lazy-dir GearData --real-data --aggregate
python tools/package_recommendations.py
python tools/verify_packages.py dist/*.zip
```

打包脚本从 InspectForEllesmereUI.toc 读取版本，仅包含插件运行文件、库、语言、纹理、GearData 和许可证。测试、文档、备份及本地信息采集器均不进入安装包。

## 自动发布 / Releases

main 的提交与 Pull Request 会自动检查 Lua、推荐数据和安装包。发布时修改 TOC 中的三段版本号，提交并推送，然后创建同版本标签：

```sh
git add InspectForEllesmereUI.toc
git commit -m "Release v2.3.1"
git push origin main
git tag v2.3.1
git push origin v2.3.1
```

v* 标签会触发 [Release addon](https://github.com/zhufei1000/InspectForEllesmereUI/actions/workflows/release.yml)：校验标签与 TOC 版本一致、运行测试、打包、生成 SHA256 校验文件，然后发布 GitHub Release。失败时可重跑任务，或在 Actions 中手动运行并填写已有标签；已发布版本不会被重复覆盖。发布使用 GitHub 自动提供的 token，无需额外配置个人令牌。

### CurseForge 自动上传（可选）

1. 在 CurseForge 账号的 [API Tokens](https://legacy.curseforge.com/account/api-tokens) 页面生成上传用 Token；
2. 在仓库 Settings → Secrets and variables → Actions 添加 secret `CF_API_TOKEN`；
3. 之后每次发布都会把安装包连同 GitHub Release 说明自动上传到 CurseForge 项目 1735274。未配置该 secret 时自动跳过；同一文件已上传时会跳过，重跑安全。
4. 可随时在 Actions 手动运行 [Verify CurseForge upload](https://github.com/zhufei1000/InspectForEllesmereUI/actions/workflows/cf-verify.yml) 做 dry-run 检查：验证 Token、游戏版本匹配和重复文件状态，不会上传。

仓库仅保留插件及公共测试/打包工具。本地信息采集器、采集配置、凭据、开发会话及备份不上传；tools 目录仅允许三个公开打包脚本进入 Git。

## License

[MIT](LICENSE). Includes code based on TinyInspect and TinyInspect-Remake; see the retained attribution in LICENSE.
