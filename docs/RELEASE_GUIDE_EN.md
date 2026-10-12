# Inspect for EllesmereUI — English Release Guide

## Project fields

| Field | Value |
| --- | --- |
| Project name | Inspect for EllesmereUI |
| Suggested slug | inspect-for-ellesmereui |
| Game | World of Warcraft |
| Edition | Retail |
| Current addon version | 2.3.0 |
| File display name | Inspect for EllesmereUI v2.3.0 |
| Upload file | InspectForEllesmereUI_2.3.0.zip |
| License | MIT, as declared in the included LICENSE |
| Required external addons | None |
| Optional integration | EllesmereUI |
| Source | https://github.com/zhufei1000/InspectForEllesmereUI |
| Issues | https://github.com/zhufei1000/InspectForEllesmereUI/issues |
| Downloads | https://github.com/zhufei1000/InspectForEllesmereUI/releases |

Choose the closest available categories for equipment, character information and interface enhancements.

### Short summary

Compact gear inspection, gems, enchants, and specialization-based recommendations with optional EllesmereUI styling.

## Project description — ready to paste

### Inspect for EllesmereUI

Inspect for EllesmereUI brings equipment details and specialization-based recommendations into a compact interface for World of Warcraft Retail.

Review your own gear or another player's equipment, check item levels, gems and enchants, and compare equipped items with the recommendations included in the addon. Optional EllesmereUI styling helps the inspection panels fit your interface.

### Features

- **Compact equipment lists:** View item levels, item names and equipment slots in aligned rows.
- **Gems and enchants:** Keep gem icons and enchant indicators close to each item name.
- **Recommendation badges:** Green BIS and TOP1–TOP3 labels identify ranked gear; gray N/R marks items outside the included rankings.
- **Enchant checks:** Green stars indicate a recommended enchant, red stars indicate a missing or different enchant, and yellow stars indicate that the status cannot be determined.
- **Specialization-based recommendations:** Browse Mythic+ and raid recommendations, including gear, gems, enchants, embellishments and consumables where data is available.
- **Equipment details:** Optional upgrade information, crafted-quality indicators, durability, set summaries and inspected equipment statistics.
- **EllesmereUI integration:** Optional styling for fonts, borders and icons.
- **Localized item names:** Equipment names come from your game client. Addon text supports English, Simplified Chinese and Traditional Chinese, with partial Russian settings translations and English fallback for other locales.

### Recommendations

The recommendation database is included in the download. Recommendations depend on the available specialization, content type, season and patch data. Rank labels reflect this dataset, and database updates are distributed with addon releases.

No separate data addon or external collection application is required. For character-specific optimization, combine these recommendations with your usual simulation tools.

### Installation

1. Download the addon ZIP.
2. Extract the **InspectForEllesmereUI** folder into:

   `World of Warcraft/_retail_/Interface/AddOns/`

3. Restart World of Warcraft and enable **Inspect for EllesmereUI** in the AddOns list.
4. Open your character window or inspect another player.

For manual installation, the TOC must be located at:

`Interface/AddOns/InspectForEllesmereUI/InspectForEllesmereUI.toc`

### Settings

Open the settings with `/ifeui` or `/inspectforellesmereui`. Use the settings to enable equipment lists, gems and enchants, durability, upgrade information, set summaries and equipment statistics.

### Compatibility

Designed for World of Warcraft Retail. EllesmereUI is optional; the addon also provides a native-style fallback.

### Support

Report bugs on [GitHub Issues](https://github.com/zhufei1000/InspectForEllesmereUI/issues). Include your game version, addon version, relevant Lua error and a screenshot when useful.

### Credits

Includes code based on TinyInspect and [TinyInspect-Remake by nc-hyw](https://github.com/nc-hyw/TinyInspect-Remake). Original attribution is retained in the included LICENSE.

## Changelog — ready to paste

### Version 2.3.0

- Public release under the name Inspect for EllesmereUI.
- Compact character and inspection equipment lists with aligned item levels and recommendation badges.
- Gem icons and enchant stars positioned beside item names.
- BIS, TOP1–TOP3 and N/R equipment indicators.
- Recommended-enchant status colors for matching, missing, different and unavailable states.
- Bundled Mythic+ and raid recommendation data.
- Optional EllesmereUI styling.
- Improved English, Simplified Chinese and Traditional Chinese localization and item-name loading fallbacks.
- Removed mouseover specialization display and its setting.

## Publishing process

### 1. Confirm the package

The current GitHub release is already available:

https://github.com/zhufei1000/InspectForEllesmereUI/releases/tag/v2.3.0

Use **InspectForEllesmereUI_2.3.0.zip**, the addon asset. GitHub's automatically generated **Source code** archives contain development files and are not the installable addon package.

The existing local package is in the workspace's `dist/` directory. It contains the addon, libraries, localization, textures, GearData and LICENSE. It excludes the local collector, configuration credentials, tests and development documents.

Before choosing a stable release type, perform a fresh in-game installation check: character and inspect panels, recommendations, gems, enchant colors and settings, both with and without EllesmereUI. Automated Lua and packaging tests have passed; these tests use mocked client APIs.

Maintainer note: the bundled recommendation metadata currently contains `internalTest = true`. Review the dataset's release status before advertising it as production-verified. Use a Beta file if this review or the in-game check is still pending. Changing the flag also requires reviewing the data tests; do not remove it solely for presentation.

The TOC declares interfaces 120100 and 120007. Select platform game-version entries that you have actually tested rather than treating the TOC declaration as proof of compatibility.

### 2. Prepare images

Prepare an original square PNG project icon of at least 400 × 400 pixels, following [CurseForge's submission guidance](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips).

Suggested screenshots and captions:

- **Character Equipment Overview** — Compact item levels, recommendation badges, gems and enchants.
- **Inspect Another Player** — Equipment details and optional inspection statistics.
- **Gear Recommendations** — Specialization-based Mythic+ and raid recommendations.
- **EllesmereUI Integration** — Inspection panels using EllesmereUI styling.
- **Addon Settings** — Options for equipment displays and inspection details.

Use screenshots of the current build. Choose a representative character and keep important text readable.

### 3. Create the CurseForge project

Sign in at the [CurseForge author portal](https://authors.curseforge.com/#/projects/create/choose-game), select World of Warcraft, and create an addon project. Fill in the project fields above, paste the short summary and detailed description, add the icon and select the declared license. Link the GitHub repository and issue tracker. Follow the platform's current [project creation instructions](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project).

Keep **Inspect for EllesmereUI** as the project name; put **v2.3.0** in the file display name.

### 4. Upload the file

In the project's Files area, upload the addon ZIP, choose tested Retail game versions, paste the changelog and choose the file's release type. Mark EllesmereUI as an optional/recommended integration if its project is available in the dependency selector. No external dependency is required for the bundled database.

CurseForge files undergo moderation. Review any requested changes, then confirm that the approved file and project page are publicly accessible. Release files are the normal default downloads; Beta files require users to opt into Beta downloads. See the [file submission instructions](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project).

### 5. Check the public download

Download the file from the public listing and confirm that it installs into one InspectForEllesmereUI folder. Check the displayed version, description, screenshots, dependencies, source link and support link. Enable the addon in-game and repeat the basic smoke check.

### 6. Optional WoWInterface listing

Reuse the name, summary, description, screenshots, changelog and addon ZIP. Follow [WoWInterface's upload FAQ](https://www.wowinterface.com/forums/faq.php?faq=managing); acknowledge the original projects in the description and follow its guidance for modified work and category selection. Wait for approval and verify the public download.

## Future releases

Update `## Version:` in InspectForEllesmereUI.toc, commit the changed source, and push main. Then create and push the matching tag, for example:

```sh
git add <changed-files>
git commit -m "Release v2.3.1"
git push origin main
git tag -a v2.3.1 -m "Inspect for EllesmereUI v2.3.1"
git push origin v2.3.1
```

GitHub Actions checks the tag against the TOC, runs tests, builds the ZIP, generates SHA256SUMS.txt and publishes a GitHub Release. Check the [Actions page](https://github.com/zhufei1000/InspectForEllesmereUI/actions) and download the new release asset.

The automation publishes the GitHub Release and, when the `CF_API_TOKEN` repository secret is configured, also uploads the same ZIP to the CurseForge project with the GitHub release notes as changelog and the Retail game versions taken from the TOC `## Interface` line. Uploads are skipped when the file already exists, so re-running the workflow is safe. WoWInterface still requires a manual upload. Update each listing's changelog and supported game versions as appropriate.

To enable automatic CurseForge uploads, generate an upload token on the CurseForge [API Tokens](https://legacy.curseforge.com/account/api-tokens) page and add it as the `CF_API_TOKEN` secret in the repository's Actions settings. Without the secret, the upload steps are skipped and the workflow publishes to GitHub only.
