
local myname, ns = ...

local l = GetLocale()
ns.L = setmetatable(l == "koKR" and {
	DISABLED_AT_RELOAD = "UI 재시작 필요",
	LOAD_ON_DEMAND = "요청시 로드",

	["Addon Management Panel"] = "애드온 관리 패널",
	["Author:"] = "작성자:",
	["Dependencies:"] = "종속:",
	["Disable All"] = "모두 비활성화",
	["Enable All"] = "모두 활성화",
	["Load"] = "로드",
	["Reload UI"] = "UI 재시작",
	["This panel can be used to toggle addons, load Load-on-Demand addons, or reload the UI.  You must reload UI to unload an addon.  Settings are saved on a per-char basis."] = "이 패널은 애드온을 토글하거나, 요청시 로드되는 애드온을 로드하거나, UI를 재시작할 때 사용됩니다.  애드온을 불러오지 않으려면 UI를 재시작해야 하며 설정은 각 캐릭터를 기준으로 저장됩니다.",
	["Version:"] = "버전:",
} or {
	DISABLED_AT_RELOAD = "Disabled on ReloadUI",
	LOAD_ON_DEMAND = "LoD",
}, {__index=function(t,i) return i end})
