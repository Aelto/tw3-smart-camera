// Code generated using Mod Settings Framework & Utilites v0.1.0 by SpontanCombust

class SC_Settings extends ISettingsMaster
{
	public var general : SC_Settings_general;

	public function ReadSettings()
	{
		var config : CInGameConfigWrapper;
		config = theGame.GetInGameConfigWrapper();

		general.modEnabledInCombat = config.GetVarValue('SCgeneral', 'SCmodEnabledInCombat');
		general.modEnabledInExploration = config.GetVarValue('SCgeneral', 'SCmodEnabledInExploration');
		general.modEnabledOnHorse = config.GetVarValue('SCgeneral', 'SCmodEnabledOnHorse');
		general.modEnabledOnBoat = config.GetVarValue('SCgeneral', 'SCmodEnabledOnBoat');
		general.modEnabledWithMouse = config.GetVarValue('SCgeneral', 'SCmodEnabledWithMouse');
		general.horizontalSensitivity = StringToFloat(config.GetVarValue('SCgeneral', 'SChorizontalSensitivity'), 0.0);
		general.overallSpeed = StringToFloat(config.GetVarValue('SCgeneral', 'SCoverallSpeed'), 0.0);
		general.cameraZoom = StringToFloat(config.GetVarValue('SCgeneral', 'SCcameraZoom'), 0.0);
		general.cameraFov = StringToInt(config.GetVarValue('SCgeneral', 'SCcameraFov'), 0);
		general.cameraHeight = StringToFloat(config.GetVarValue('SCgeneral', 'SCcameraHeight'), 0.0);
		general.cameraHorizontalPosition = StringToFloat(config.GetVarValue('SCgeneral', 'SCcameraHorizontalPosition'), 0.0);
		general.horseCameraZoom = StringToFloat(config.GetVarValue('SCgeneral', 'SChorseCameraZoom'), 0.0);
		general.explorationAutoCenterEnabled = config.GetVarValue('SCgeneral', 'SCexplorationAutoCenterEnabled');

	}

	public function WriteSettings()
	{
		var config : CInGameConfigWrapper;
		config = theGame.GetInGameConfigWrapper();

		config.SetVarValue('SCgeneral', 'SCmodEnabledInCombat', general.modEnabledInCombat);
		config.SetVarValue('SCgeneral', 'SCmodEnabledInExploration', general.modEnabledInExploration);
		config.SetVarValue('SCgeneral', 'SCmodEnabledOnHorse', general.modEnabledOnHorse);
		config.SetVarValue('SCgeneral', 'SCmodEnabledOnBoat', general.modEnabledOnBoat);
		config.SetVarValue('SCgeneral', 'SCmodEnabledWithMouse', general.modEnabledWithMouse);
		config.SetVarValue('SCgeneral', 'SChorizontalSensitivity', FloatToString(general.horizontalSensitivity));
		config.SetVarValue('SCgeneral', 'SCoverallSpeed', FloatToString(general.overallSpeed));
		config.SetVarValue('SCgeneral', 'SCcameraZoom', FloatToString(general.cameraZoom));
		config.SetVarValue('SCgeneral', 'SCcameraFov', IntToString(general.cameraFov));
		config.SetVarValue('SCgeneral', 'SCcameraHeight', FloatToString(general.cameraHeight));
		config.SetVarValue('SCgeneral', 'SCcameraHorizontalPosition', FloatToString(general.cameraHorizontalPosition));
		config.SetVarValue('SCgeneral', 'SChorseCameraZoom', FloatToString(general.horseCameraZoom));
		config.SetVarValue('SCgeneral', 'SCexplorationAutoCenterEnabled', general.explorationAutoCenterEnabled);

		theGame.SaveUserSettings();
	}
}

struct SC_Settings_general
{
	var modEnabledInCombat : bool;
	var modEnabledInExploration : bool;
	var modEnabledOnHorse : bool;
	var modEnabledOnBoat : bool;
	var modEnabledWithMouse : bool;
	var horizontalSensitivity : float;
	var overallSpeed : float;
	var cameraZoom : float;
	var cameraFov : int;
	var cameraHeight : float;
	var cameraHorizontalPosition : float;
	var horseCameraZoom : float;
	var explorationAutoCenterEnabled : bool;
}

