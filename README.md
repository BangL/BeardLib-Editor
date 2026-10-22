# BeardLib-Editor

BeardLib-Editor is a tool that allows you to edit and create things like maps & environments.

## Installation
1. Install [RAID-SuperBLT](https://modworkshop.net/mod/49744)
2. Install [RAIDWW2-BeardLib](https://modworkshop.net/mod/49760)
3. After downloading the editor by clicking `Code` -> `Download ZIP`, unzip the contents of the ZIP file in the mods folder of the game.
4. Launch the game and click `Yes` on the dialog that pops up. These files are required.

If you install the dev branch, make sure you have the latest BeardLib commit https://github.com/RAIDModding/RAIDWW2-BeardLib it's possible that branch uses unreleased features not found in the public (MWS) version.

## Custom jobs
A job is a raid: one mission in `tweak_data.operations.missions` that points at exactly one level. The editor creates and edits them in the project editor (`Create` -> `job`, or `Actions` -> `CloneJob` to start from a vanilla raid); this is what ends up in the `main.xml` of the map:
```xml
<table name="mymap" min_lib_ver="5.1">
    <job id="mymap" level_id="mymap" region="germany" xp="2000" music_id="camp"/>
    <level id="mymap"/>
</table>
```
`min_lib_ver="5.1"` is the first BeardLib version with jobs. The name and the briefing are the strings `job_[ID]_name` and `job_[ID]_brief` of your localization.

| Attribute | Meaning |
| --- | --- |
| `level_id` | The level of the job, defaults to the job id. |
| `region`, `xp`, `music_id` | Region (default `germany`), xp (default 2000), music (default `camp`). |
| `hidden` | Not listed in the raid selection (for jobs that are only the event of an operation). |
| `stealth_description`, `start_in_stealth` | The text on the selection (`whisper_info_starts_loud`, `whisper_info_starts_stealth`, `whisper_info_mostly_stealthable`, `whisper_info_completely_stealthable`) and whether the mission starts in stealth. One follows the other: every description but `starts_loud` starts in stealth (the player spawns with the melee weapon in hand), and `start_in_stealth` alone gives `starts_stealth`. Default starts loud. The editor only has the description, an attribute you set by hand wins (e.g. `start_in_stealth` with `starts_loud` as the tutorial does). |
| `consumable` | An outlaw raid: unlocked with the outlaw intel (the documents in the levels) and used up when it is played. The intel unlocks a random outlaw raid from what the player who picks it up has, not the one of the level with the document, and a custom one is left out while a player in the lobby could not play it (no BeardLib / no map). More custom outlaw raids make the vanilla ones less likely. |
| `dogtags` | How many dogtags are placed: `small`, `medium` (default) or `large`. The game hands out a random total between a minimum and a maximum (plus a bonus per difficulty) over the dogtag units of the level and removes the rest, a job without it gets no dogtags. |
| `dogtags_min`, `dogtags_max`, `dogtags_diff_bonus`, `dogtags_min_dist` | Override the values of the preset (`dogtags_min_dist`: smallest distance between two dogtags, default 200). |
| `greed_items_min`, `greed_items_max` | The same for the greed items (the small gold loot), default 300 to 500. |
| `excluded_continents` | Comma separated continents of the level that are not created when it is played as a raid (vanilla raids exclude `operation`). |
| `audio_briefing_id`, `short_audio_briefing_id` | Sound events of the audio briefing and of the selection. They have to exist in the game, custom sounds are not possible. |
| `loading` | Loading screen: `image` is a file name from `ui/loading_screens/`, `text` a localization id. |
| `camp_objective_id` | The objective in the camp after selecting the raid. |
| `mission_flag`, `mission_state` | Global state flags the mission scripts can check (advanced). |
| `merge_data` | Anything else is merged into the mission data. |

**Icons.** The game shows an icon 1:1 in the size of its image, so each place has its own, in `assets/guis/textures/mods/icons` (`.png` or `.texture`): `job_[ID].png` is the folder on the mission selection (about 392x392), `job_[ID]_menu.png` the icon in the list and `job_[ID]_hud.png` the HUD one (both 56x56). A missing one is the default icon, one that is far too big for the list or the HUD is ignored. You can also set `icon_menu`, `icon_menu_big` and `icon_hud` to the ids of existing icons (e.g. the ones of a vanilla raid), or `icon` (texture path, with `icon_rect`) for the folder.

**Intel photos.** `job_[ID]_photo_1.png`, `job_[ID]_photo_2.png` and so on (up to 12, about 416x288) in the same folder; the texts are the strings `job_[ID]_photo_[N]_title` and `job_[ID]_photo_[N]_description`. The editor adds and removes them in the job menu and edits their texts.

**Loading screen.** A `loading.png` (or `loading.texture`) in the folder of the level (`levels/[level id]/`) is the loading screen, the level's menu can set it. Without one the loading screen of the tutorial is used.

**Camp objective.** The objective shown in the camp after selecting the raid uses the vanilla text `obj_camp_goto_raid`. Set `camp_objective_id` to `[id]` and add `[id]_hl` and `[id]_desc` strings for a text of your own.

## Custom operations
An operation is a chain of events, every event is a job (see above) of the same project. In the project editor: `Create` -> `operation` (the new operation gets all jobs of the project as events) or `Actions` -> `CloneOperation` (clones a vanilla operation, every event becomes a hidden job with a clone of its level). Add the jobs as `hidden` if they should only be played as part of the operation.

```xml
<job id="raid_a" level_id="level_a" hidden="true"/>
<job id="raid_b" level_id="level_b" hidden="true"/>
<operation id="my_op" region="germany" xp="5000">
    <event job="raid_a"/>
    <event job="raid_b" row="2"/>
    <event job="raid_c" row="2"/>
</operation>
```

* The events are played one after another in the camp and the levels of their jobs. Events with the same `row` are alternatives (one of them is picked every time the operation is started), the default is one row per event.
* Optional: `region`, `xp` (for completing the operation), `allow_free_play` (the events can be played one by one, default true, `"false"` switches it off), `hidden`, `audio_briefing_id`, `short_audio_briefing_id`, `loading`, `camp_objective_id`, `merge_data`, and the photos like a job.
* Strings: `job_[ID]_name` and `job_[ID]_brief`, like a job. Icons: `job_[ID]_menu.png` (56x56, the list) and `job_[ID]_hud.png` (224x224, the paper and the loading screen), in the same folder as the ones of a job.
* Everything else (level, loot, loading screen, objectives) comes from the job of the event.
* Custom operations are always unlocked. The profile guard keeps their save slots out of the profile: a custom operation cannot be continued after the game was closed.

## Migrating from narratives
The PAYDAY 2 `<narrative>` module (a chain of levels with contacts, payout, crimenet data) does not exist on RAID and the library reports an error for it.
1. Replace `<narrative id="x">` with `<job id="x" level_id="[the level]"/>`, drop `contact`, `chain`, `contract_cost`, `payout`, `crimenet_*` and the other crimenet values. A chain of several levels is an `<operation>` now, see above.
2. Rename the `heist_[ID]_name`/`heist_[ID]_brief` strings to `job_[ID]_name`/`job_[ID]_brief`.
3. Set `min_lib_ver="5.1"` (the first version with `<job>`) in your `main.xml`.

## Brushes
The editor writes the massunit (`massunit.massunit`) of a level itself, no external tool (the old `MassunitMaker.exe` needing .NET is not used anymore).
* A brush only works if the level loads a package that has it. When you select one that is missing, the editor offers a package that has it (choose a small one).
* The layer keeps the brushes as data and shows them by loading the massunit again after a stroke, so the picture goes empty for a moment and comes back; green markers show the new ones meanwhile. Saving writes `massunit.massunit` and the brush entry of the world.

## Regenerating the Data files
`Data/` (asset paths of the game) is created from a `packages.txt`. To create it without Windows:
```
python3 Tools/packages_txt.py            # see --help
```
It reads the game's `assets/` bundles and the hashlist of the official "RAID World War II Modding Tools" (Steam, `data/hashlist`) and writes `packages.txt` into the editor folder. Start the game, the editor then writes the Data files and deletes it (back up `Data/` first).
Files whose name is not in the hashlist are left out, so update the Modding Tools after game updates.

## Guides
https://www.youtube.com/playlist?list=PLRSASA7UrjTsX1WWG6kStRTK51DKSEDPn \
https://wiki.modworkshop.net/books/beardlib-editor-tutorials \
https://www.payday2maps.net/guides/

## Report a Bug/Request a Feature
[https://github.com/simon-wh/PAYDAY-2-BeardLib-Editor/issues](https://github.com/RAIDModding/BeardLib-Editor/issues)

## Ask a Question
Payday 2 Maps Discord Server - https://discord.gg/fn62qaq

Painday 2 (maker of the video tutorials) Discord Server - https://discord.gg/RNBUnrN7

ModWorkshop Discord Server - https://discord.gg/Eear4JW

## Help Needed
We're looking for developers that will work together on the editor.

Your best friend in all of this is knowing how to look for the pieces of code that correspond to parts of the editor. Be it in the decompiled files of the game or the editor's code.

Make sure you are using a good code editor like VSCode. This will allow you to quickly search the code and the decompiled code of the game [https://github.com/steam-test1/Raid-WW2-Lua-Complete](https://github.com/steam-test1/Raid-WW2-Lua-Complete).

Make sure you have an empty file called developer.txt in the mods folder (turns on the console) and run the following command: blt.forcepcalls(true) - this let's you not crash the moment you hit a random error.

The editor is equipped with a code refresher, editing any file will refresh parts of the editor.

The real editor uses what is called in the decompiled code 'EWS' ('External Window System', based on wxWidgets). Unfortunately porting this kind of GUI is easier said than done. Instead of that we use https://github.com/simon-wh/PAYDAY-2-BeardLib/wiki/MenuUI and have a class that simplfies the process of creation a little https://github.com/Luffyyy/BeardLib-Editor/blob/master/Classes/MenuUIExt.lua
