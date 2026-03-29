# Bart — Wyatt's World GUID Pre-Assignment Block

**Decision:** D-WYATT-GUIDS  
**Author:** Bart (Architect)  
**Date:** 2026-08-23  
**Purpose:** Prevent GUID collisions during parallel authoring (WAVE-1). Moe and Flanders use ONLY GUIDs from this block. No independent GUID generation.

---

## Rules

1. **Sequential assignment:** Use GUIDs in order from each category. Don't skip or shuffle.
2. **No reuse:** Each GUID is used exactly once.
3. **Overflow:** If a category runs out, take from the Overflow pool (end of list).
4. **Format:** Windows `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}` — curly braces included.

---

## World Definition (1 GUID)

| # | GUID | Entity | Owner |
|---|------|--------|-------|
| W1 | `{6F129CCE-4798-446D-9CD8-198B36F04EF0}` | wyatt-world.lua (world definition) | Bart |

## Room GUIDs (7 GUIDs — Moe)

| # | GUID | Room | File |
|---|------|------|------|
| R1 | `{2CC1419B-3F68-44DD-BDA6-A5627650C410}` | MrBeast's Challenge Studio (Hub) | beast-studio.lua |
| R2 | `{D4B094DA-842B-4011-B9A0-BE0007825BE4}` | The Feastables Factory | feastables-factory.lua |
| R3 | `{4DB5FAE6-6FB1-4CDA-9292-FC76B0B50581}` | The Money Vault | money-vault.lua |
| R4 | `{17873274-B097-4669-B4D5-2B6524579835}` | The Beast Burger Kitchen | beast-burger-kitchen.lua |
| R5 | `{C9E72A2F-E1AD-465C-A4E0-9AE69816F752}` | The Last to Leave Room | last-to-leave.lua |
| R6 | `{611A8C30-3C89-4018-B143-5448F383D9E1}` | The Riddle Arena | riddle-arena.lua |
| R7 | `{803085D7-5E49-4AAC-A035-391148E7AB5C}` | The Grand Prize Vault | grand-prize-vault.lua |

## Level GUID (1 GUID — Flanders)

| # | GUID | Entity | File |
|---|------|--------|------|
| L1 | `{440AC83D-D479-4832-A2F2-482FC4E5014A}` | Level 01 — MrBeast's Challenge Arena | level-01.lua |

## Object GUIDs (~70 GUIDs — Flanders)

### Challenge Props (~25)

| # | GUID | Object (Suggested ID) | Room |
|---|------|-----------------------|------|
| O1 | `{9F5DA6D1-65CE-49ED-B7B5-88E98DB6B1ED}` | big-red-button | Studio |
| O2 | `{716FEDF0-744D-49FC-9011-7F654B6AA926}` | colored-button-1 | Studio |
| O3 | `{2825C8B0-5C2E-4D51-9D82-B2E846ABB19B}` | colored-button-2 | Studio |
| O4 | `{BD0D6F0A-CACB-4A9B-8FAA-0BFF23765109}` | colored-button-3 | Studio |
| O5 | `{8D3ABE0B-1C7C-46C6-A8A6-7F5D17F505C1}` | colored-button-4 | Studio |
| O6 | `{CD4C6BA7-8C74-4633-9D2D-E9A0C321F667}` | sorting-bin-1 | Feastables |
| O7 | `{4A78EF75-221A-4EB4-813E-D84F6264AC8E}` | sorting-bin-2 | Feastables |
| O8 | `{F00C6588-541C-4247-9302-2E84457832BC}` | sorting-bin-3 | Feastables |
| O9 | `{4E65A9FC-3589-4E58-920D-1582C6CA5D1D}` | sorting-bin-4 | Feastables |
| O10 | `{5C84FB47-5B28-43E0-B0B9-4E61A6BAAEEA}` | conveyor-belt | Feastables |
| O11 | `{27D91EB0-EF89-49F9-B866-EF370421DEE4}` | safe-keypad | Money Vault |
| O12 | `{40995C15-53D6-4007-A143-C19D15BFE5D0}` | combo-dial-1 | Grand Prize |
| O13 | `{BDC4B5E9-351B-4525-947C-198E0EE38488}` | combo-dial-2 | Grand Prize |
| O14 | `{0498BDF9-8FCF-4B6F-AAE5-7C9DD5C94BB7}` | combo-dial-3 | Grand Prize |
| O15 | `{24687D31-F9BA-4D64-9D13-41A702321885}` | burger-plate | Burger Kitchen |
| O16 | `{A6F518FC-75C2-4190-9F1F-CD1BFAA72D42}` | riddle-podium-1 | Riddle Arena |
| O17 | `{5C3488B6-2085-4CC1-BB7E-31A416076199}` | riddle-podium-2 | Riddle Arena |
| O18 | `{10637A5B-EC0C-4FE1-91EC-5A9C30F28AB3}` | riddle-podium-3 | Riddle Arena |
| O19 | `{047D49A9-1784-497D-9D5C-B2640FBEFE5D}` | riddle-board-1 | Riddle Arena |
| O20 | `{49B98212-1B73-4F93-9EF9-42FB700494EB}` | riddle-board-2 | Riddle Arena |
| O21 | `{177C7743-9798-4D84-B031-7F2F2AD4691F}` | riddle-board-3 | Riddle Arena |
| O22 | `{D26CF949-E621-4E59-BEFF-8128BD451FC3}` | treasure-chest | Grand Prize |
| O23 | `{192A5686-FFB0-400B-8701-D89BE7F80ECA}` | found-it-box | Last to Leave |
| O24 | `{8303FFE1-6084-472B-B1D1-86785B770BB4}` | scoreboard | Studio |
| O25 | `{60D6B6CC-EACC-4276-8DD4-AE7086ED86C0}` | confetti-cannon | Studio |

### Prize Items (~8)

| # | GUID | Object (Suggested ID) | Room |
|---|------|-----------------------|------|
| O26 | `{18B92F77-B240-4F25-B937-8EE913A3876C}` | golden-trophy | Grand Prize |
| O27 | `{4CB1E560-2A3D-4213-AA15-A0EA68FFAE62}` | beast-burger-coupon | Burger Kitchen |
| O28 | `{19DC8357-1A3F-441F-BBDF-67A32EC59910}` | gold-medal | Studio |
| O29 | `{3D8BCED0-A099-4813-80AA-7EF0003F90B3}` | silver-medal | Studio |
| O30 | `{6462237C-4F5E-4E9E-A312-1B697F1131F8}` | bronze-medal | Studio |
| O31 | `{96E76752-10A8-4246-8DE5-A715F99DD1F9}` | cash-bundle-1 | Money Vault |
| O32 | `{DD2401C1-04DC-428B-B976-D619CD64DA8C}` | cash-bundle-2 | Money Vault |
| O33 | `{93A63E5F-137A-4214-BD5D-E7482CD82BD6}` | confetti-prize | Studio |

### MrBeast Brand Items (~10)

| # | GUID | Object (Suggested ID) | Room |
|---|------|-----------------------|------|
| O34 | `{2EA32F03-0C15-4E28-AD44-C45C59F5E3AD}` | feastables-bar-chocolate | Feastables |
| O35 | `{50C54DD6-443B-4A8B-B094-9E502B4F5C19}` | feastables-bar-crunch | Feastables |
| O36 | `{35EEB9BC-BF45-4758-89B3-38DA9E012A9C}` | feastables-bar-caramel | Feastables |
| O37 | `{EC189B6E-D0BF-4E03-AA6E-BC0B09CE3D71}` | feastables-bar-peanut | Feastables |
| O38 | `{38D3D955-9347-4757-A0CA-32A89113339A}` | feastables-bar-mystery | Feastables |
| O39 | `{266B4CCB-E5DF-4E08-B06C-4F4348866800}` | burger-bun | Burger Kitchen |
| O40 | `{2C987FD8-30D2-4317-86F5-70B7DFCC9B8D}` | burger-patty | Burger Kitchen |
| O41 | `{FA9E9331-6D10-4119-8870-E045FF733198}` | burger-cheese | Burger Kitchen |
| O42 | `{BC9CF3AE-C04C-4382-87AC-976FD65B18D6}` | burger-lettuce | Burger Kitchen |
| O43 | `{69D9EDEE-6BD5-4790-B2D7-DFAEDB366062}` | burger-tomato | Burger Kitchen |

### Reading/Clue Objects (~12)

| # | GUID | Object (Suggested ID) | Room |
|---|------|-----------------------|------|
| O44 | `{1A16AA44-5759-464B-9B4B-4A77F771816D}` | welcome-sign | Studio |
| O45 | `{AA2523C8-4F21-4EE7-BE0A-C3624EBCA90E}` | feastables-instruction-sign | Feastables |
| O46 | `{F447E8E0-025E-4044-A9F5-3FFFCFF9CE40}` | money-instruction-sign | Money Vault |
| O47 | `{B357D9A0-7140-4241-BE2E-6906712E14AA}` | burger-recipe-card | Burger Kitchen |
| O48 | `{38BDC2EB-57CB-43E6-A1AC-47B08D30900B}` | last-to-leave-sign | Last to Leave |
| O49 | `{6F9FD8E9-6CBA-43FF-9EB4-ED115BF4AB9F}` | mrbeast-letter | Grand Prize |
| O50 | `{91F50759-5913-4820-A626-DF9F6BABB2E7}` | bin-label-1 | Feastables |
| O51 | `{412E5486-DB2F-46E4-B65B-0F4225AF4394}` | bin-label-2 | Feastables |
| O52 | `{5FB8C00D-7E5C-4ED1-A8E4-689644721E7D}` | bin-label-3 | Feastables |
| O53 | `{F0656D63-30AC-419B-AA5F-1CFFF6A08627}` | bin-label-4 | Feastables |
| O54 | `{9FC89B10-18B6-48DD-8A17-503464E1EA64}` | riddle-instruction-sign | Riddle Arena |
| O55 | `{FE830E4C-E328-44B9-95A5-329C840A8B33}` | grand-prize-instruction-sign | Grand Prize |

### Set Dressing (~15)

| # | GUID | Object (Suggested ID) | Room |
|---|------|-----------------------|------|
| O56 | `{C3A19474-D64E-472A-8067-B47AF42C834F}` | giant-screen-1 | Studio |
| O57 | `{F9187200-8168-4263-BE31-441FEA1554AF}` | giant-screen-2 | Studio |
| O58 | `{B0EE409D-EAB0-418A-860B-F6B44C7045A3}` | camera-1 | Studio |
| O59 | `{EFB7D842-0CB9-4C76-BEA2-7E9445F0761B}` | camera-2 | Studio |
| O60 | `{30381B85-3096-4D27-AF3D-3E9BE5DF3CD8}` | speaker-1 | Studio |
| O61 | `{C2C4B9D1-8CF7-43CD-AA94-7A4D97448DD7}` | speaker-2 | Studio |
| O62 | `{FE22C9C9-8A3F-4BB5-822F-77A3D1F56356}` | banner-1 | Studio |
| O63 | `{1502CDEE-BD88-4420-B7F4-5836CB23228D}` | banner-2 | Feastables |
| O64 | `{5EC41C0A-6197-478E-BDED-BDFB7F9697EF}` | spotlight-1 | Riddle Arena |
| O65 | `{81E798F5-E0CA-487C-B384-D1486CBA4FC4}` | spotlight-2 | Riddle Arena |
| O66 | `{AB454E9B-B835-4BE0-B1E9-E495810AD922}` | streamers | Grand Prize |
| O67 | `{57AD9D23-E74C-4F2F-BB89-F5A1FDC78029}` | grill | Burger Kitchen |
| O68 | `{AFA162AB-1204-4513-A058-7AFDC143A4AA}` | ingredient-shelf | Burger Kitchen |
| O69 | `{9488D15E-9C7D-4EE3-B308-92BAE9A1AEF6}` | money-table-1 | Money Vault |
| O70 | `{DF578867-AE5C-42D1-B7E1-CF9EB48451BE}` | money-table-2 | Money Vault |

### Last to Leave — Fake/Real Objects (~5)

| # | GUID | Object (Suggested ID) | Room |
|---|------|-----------------------|------|
| O71 | `{4AAA3182-509C-4835-9F11-22AD13F47164}` | fake-clock | Last to Leave |
| O72 | `{5CF8A580-7113-4FE2-B05D-82442D09EE3F}` | fake-book | Last to Leave |
| O73 | `{7F8B62C8-631C-499C-A84B-449425ADA247}` | fake-lamp | Last to Leave |
| O74 | `{9DB3432B-9E2B-4528-A281-80654EB0428D}` | real-couch | Last to Leave |
| O75 | `{DECCD937-7991-43D4-AE63-0DAF1A695BF9}` | real-tv | Last to Leave |

### Overflow Pool (spare GUIDs)

| # | GUID | Reserved For |
|---|------|-------------|
| X1 | `{573A537C-5C14-4362-A61A-8C99D0D4DE3B}` | (spare) |
| X2 | `{F182B100-D7A2-4C55-81EC-58CECFA45752}` | (spare) |
| X3 | `{67D3C061-CC24-4B6E-9252-ECF7A8A6210B}` | (spare) |
| X4 | `{B1442FE7-9BDF-410C-848E-E576FE4EC78F}` | (spare) |
| X5 | `{709DDA2B-C858-414A-BC7D-2EDBD376CFD9}` | (spare) |

---

## Usage Protocol

1. Moe uses Room GUIDs (R1–R7) for room files.
2. Flanders uses Level GUID (L1) for level-01.lua.
3. Flanders uses Object GUIDs (O1–O75) for object files.
4. If more objects are needed, use Overflow (X1–X5) first, then generate new GUIDs and append to this document.
5. **No agent generates their own GUIDs.** All GUIDs come from this block.
6. Object IDs in this table are **suggestions**. Flanders may rename object IDs during implementation, but GUID assignment is fixed.

---

**Author:** Bart (Architect)  
**Date:** 2026-08-23
