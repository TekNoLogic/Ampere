
if GetLocale() ~= "koKR" then return end
local L, _, ns = { }, ...
ns.L = L

L.DISABLED_AT_RELOAD = "UI 재시작 필요"
L.LOAD_ON_DEMAND = "요청시 로드"

L["Addon Management Panel"] = "애드온 관리 패널"
L["Author:"] = "작성자:"
L["Dependencies:"] = "종속:"
L["Disable All"] = "모두 비활성화"
L["Enable All"] = "모두 활성화"
L["Load"] = "로드"
L["Reload UI"] = "UI 재시작"
L["This panel can be used to toggle addons, load Load-on-Demand addons, or reload the UI.  You must reload UI to unload an addon.  Settings are saved on a per-char basis."] = "이 패널은 애드온을 토글하거나, 요청시 로드되는 애드온을 로드하거나, UI를 재시작할 때 사용됩니다.  애드온을 불러오지 않으려면 UI를 재시작해야 하며 설정은 각 캐릭터를 기준으로 저장됩니다."
L["Version:"] = "버전:"
