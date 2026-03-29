# Cooldown Companion

## [1.10.22.1](https://github.com/Direction6275/Cooldown-Companion/tree/1.10.22.1) (2026-03-27)
[Full Changelog](https://github.com/Direction6275/Cooldown-Companion/compare/1.10.21...1.10.22.1) 

- Merge pull request #138 from Direction6275/deferred-cooldowns  
    Fix deferred cooldown flickering for items and spells  
- Fix text mode {status} token showing "Ready" during deferred cooldowns  
    When a cooldown is deferred (timer hasn't started), the {status} token  
    fell through to "Ready" because timeRemaining was nil. Now shows "..."  
    in cooldown color to indicate the spell is on cooldown but waiting.  
- Fix deferred cooldown flickering for items and spells  
    When a cooldown timer hasn't started yet (e.g. Healthstone used in  
    combat, Feign Death while the buff is active), the API returns unstable  
    values that caused the cooldown swipe to restart every tick, producing  
    visible flickering.  
    Items: C\_Item.GetItemCooldown returns enableCooldownTimer=false with an  
    advancing startTime during deferment. Now suppresses the swipe and sets  
    a \_cooldownDeferred flag for downstream consumers.  
    Spells: C\_Spell.GetSpellCooldown returns isEnabled=false during  
    deferment. The existing isActive gate already prevented the swipe, but  
    desaturation and visibility incorrectly treated the button as off  
    cooldown. Now correctly recognized as deferred.  
    The \_cooldownDeferred flag is threaded through desaturation, visibility,  
    bar mode, and text mode so deferred buttons appear dimmed and respect  
    hide-while-not-on-cooldown rules without animation or timer text.  
- Add Discord invite link to gear dropdown menu  
- Merge pull request #137 from Direction6275/per-button-loading  
    Add per-button disable/enable toggle  
- Suppress misleading warn badge on user-disabled buttons  
    When a button is disabled via the new toggle, IsButtonUsable returns  
    false which triggered the "Spell/item unavailable" warning badge  
    alongside the disabled badge. Gate the warn badge on enabled ~= false  
    so only genuinely unavailable spells show the warning.  
- Add per-button disable/enable toggle  
    Buttons can now be individually disabled via right-click context menu  
    in Column 2, preventing them from loading at runtime without removing  
    them from the group. Disabled buttons show grayed out with a disabled  
    badge in both normal and browse modes.  
- Merge pull request #136 from Direction6275/group-icons  
    Add custom icon support for groups in Column 1  
- Simplify container icon picker and merge folder-move guards  
    Remove unnecessary drag support from container picker (matches folder  
    picker pattern) and add strata/level explanatory comments. Merge the  
    two adjacent `if folderId` blocks in MoveGroupToFolder into one.  
- Add custom icon support for groups in Column 1  
    Allow non-foldered groups to display a 32x32 icon via right-click  
    "Set Group Icon..." menu item, using the same Blizzard icon picker  
    as folders and buttons. Icons are cleared when a group is moved  
    into a folder. "Clear Custom Icon" appears in the menu when set.  
