/***********************************************************************/
/** 	© 2015 CD PROJEKT S.A. All rights reserved.
/** 	THE WITCHER® is a trademark of CD PROJEKT S. A.
/** 	The Witcher game is based on the prose of Andrzej Sapkowski.
/***********************************************************************/




state Sailing in CR4Player extends UseGenericVehicle
{
	private var boatLogic : CBoatComponent;
	private var remainingSlideDuration : float;
	private var vehicleCombatMgr : W3VehicleCombatManager;
	private var dismountRequest : bool;
	
	private const var angleToSeatFromBack : float;
	private const var angleToSeatFromForward : float;	
	
	default remainingSlideDuration = 0.f;
	default angleToSeatFromBack	= 150.0f;
	default angleToSeatFromForward = 30.0f;
	
	
	
	
	
	protected function Init()
	{
		super.Init();

		if( !vehicleCombatMgr )
		{
			vehicleCombatMgr = new W3VehicleCombatManager in this;
		}
		
		parent.UnblockAction( EIAB_Crossbow, 'DismountVehicle2' );	
		dismountRequest = false;
		
		vehicleCombatMgr.Setup( parent, vehicle );
		vehicleCombatMgr.GotoStateAuto();
		vehicle.SetCombatManager( vehicleCombatMgr );
		
		parent.SetOrientationTarget( OT_Camera );
		
		boatLogic = (CBoatComponent)vehicle; 
		ProcessBoatSailing();
	}
	
	event OnEnterState( prevStateName : name )
	{
		var commonMapManager : CCommonMapManager = theGame.GetCommonMapManager();
		
		super.OnEnterState( prevStateName );
		
		theTelemetry.LogWithName( TE_STATE_SAILING );
		
		parent.SetBehaviorVariable( 'keepSpineUpright', 0.f );	
		commonMapManager.NotifyPlayerMountedBoat();
		
		InitCamera();
	}
	
	event OnLeaveState( nextStateName : name )
	{ 
		var commonMapManager : CCommonMapManager = theGame.GetCommonMapManager();
		
		theInput.SetContext( parent.GetExplorationInputContext() );	
		
		parent.SetBehaviorVariable( 'keepSpineUpright', 1.f );
		commonMapManager.NotifyPlayerDismountedBoat();		
		
		super.OnLeaveState( nextStateName );
		
		theInput.GetContext();
	}
	
	
	
	
	
	entry function ProcessBoatSailing()
	{
		var axis : float;
		
		parent.SetCleanupFunction( 'SailingCleanup' );
		
		LogAssert( vehicle, "Sailing::ProcessBoatSailing - vehicle is null" );
				
		while( !dismountRequest )
		{
			FindTarget();
			
			Sleep( 0.2f );
			
			
			
			
			
		}
		
		parent.ClearCleanupFunction();
		
		((CPlayerStateDismountBoat)parent.GetState('DismountBoat')).SetupState( boatLogic, DT_normal );
		((CPlayerStateDismountBoat)parent.GetState('DismountBoat')).DismountFromPassenger( false );
		parent.GotoState( 'DismountBoat', true );
	}
	
	cleanup function SailingCleanup()
	{
		vehicle.ToggleVehicleCamera( false );
		
		vehicle.OnDismountStarted( parent );
		vehicle.OnDismountFinished( parent, thePlayer.GetRiderData().sharedParams.vehicleSlot );	
		
		parent.EnableCollisions( true );		
		parent.RegisterCollisionEventsListener();
	}
	
	function DismountVehicle()
	{
		dismountRequest = true;
	}
	
	event OnReactToBeingHit( damageAction : W3DamageAction )
	{
		var boatHitDirection : int;
		var angleDistance : float;
		var target : CNode;
		
		target = damageAction.attacker;
		
		if ( target )
		{
			angleDistance = NodeToNodeAngleDistance(target,parent);
			if ( AbsF(angleDistance) < 45 )
				boatHitDirection = 0; 
			else if ( AbsF(angleDistance) > 135 )
				boatHitDirection = 1; 
			else if ( angleDistance > 45 )
				boatHitDirection = 3; 
			else if ( angleDistance < -45 )
				boatHitDirection = 2; 
			else
				boatHitDirection = 0; 
			
		}
		else
		{
			boatHitDirection = 0;
		}
		
		parent.SetBehaviorVariable( 'boatHitDirection', boatHitDirection);
		
		virtual_parent.OnReactToBeingHit( damageAction );
	}
	
	
	
	
	
	
	
	
	private var angleDamper	: float;
	private var offsetDamper : float;
	private var rudderDamper : float;
	private var cameraSide : float;
	
	default rudderDamper = 0.f;
	default cameraSide = 1.f;
	
	private function InitCamera()
	{
		
		camera.ChangePivotRotationController( 'Boat_RC' );
		camera.ChangePivotDistanceController( 'Boat_DC' );
	}
	
	
	private final function GetGearRatio( gear : int ) : float
	{
		if( ( gear == 1 ) || ( gear == -1 ) )
		{
			return 1.0f;
		}
		
		if( gear == 2 )
		{
			return 1.5f;
		}
		
		if( gear == 3 )
		{
			return 2.2f;
		}
		
		return 0.0f;
	}
	
	private var m_shouldEnableAutoRotation : bool;
	
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{
		var turnFactor  : float;
		var velocityRatio : float;		
		var sailCameraOffset : float;
		
		var fovDistPitch : Vector;
		var offsetZ : float;
		var offsetUp : Vector;
		var sailOffset : float;
		var boatComponent: CBoatComponent;
		
		var boatPPC : CCustomCameraBoatPPC;
		var cameraToBoatDot : float;
		var turnFactorSum : float;
		
		var camera : CCustomCamera;
		var angleDist : float;
		
		parent.UpdateLookAtTarget();
		
		
		camera = (CCustomCamera)theCamera.GetTopmostCameraObject();
		
		if( theInput.LastUsedGamepad() )
		{
			angleDist = AngleDistance( parent.GetHeading(), camera.GetHeading() );
			
			if( thePlayer.GetAutoCameraCenter() || ( !m_shouldEnableAutoRotation && AbsF(angleDist) <= 30.0f ) )
			{
				m_shouldEnableAutoRotation = true;
			}
			else if( m_shouldEnableAutoRotation && !thePlayer.GetAutoCameraCenter() && camera.IsManualControledHor() )
			{
				m_shouldEnableAutoRotation = false;
			}
		}
		else
		{
			m_shouldEnableAutoRotation = thePlayer.GetAutoCameraCenter();
		}
		
		camera.SetAllowAutoRotation( m_shouldEnableAutoRotation );
		
		
		
		boatComponent = (CBoatComponent)vehicle;
		if( boatComponent )
		{
			boatComponent.localSpaceCameraTurnPercent = VecDot2D( camera.GetHeadingVector(), VecCross( boatComponent.GetHeadingVector(), Vector( 0.0f, 0.0f, 1.0f ) ) );
			
			
			if( AbsF( boatComponent.localSpaceCameraTurnPercent ) < 0.1f )
			{
				boatComponent.localSpaceCameraTurnPercent = 0.0f;
			}
			
			
			if( VecDot2D( camera.GetHeadingVector(), boatComponent.GetHeadingVector() ) < 0.0f )
			{
				boatComponent.localSpaceCameraTurnPercent = SgnF( boatComponent.localSpaceCameraTurnPercent );
			}
		}
		
		ShouldEnableBoatMusic();

		turnFactor	= theInput.GetActionValue( 'GI_AxisLeftX' );		
		
		turnFactorSum = AbsF( turnFactor + boatComponent.localSpaceCameraTurnPercent );		
		if( turnFactorSum > 1.0f )
		{
			turnFactorSum = AbsF( turnFactor * 2.0f + boatComponent.localSpaceCameraTurnPercent );
			turnFactor = ( turnFactor * 2.0f ) / turnFactorSum + boatComponent.localSpaceCameraTurnPercent / turnFactorSum;
		}
		else
		{
			turnFactor = turnFactor + boatComponent.localSpaceCameraTurnPercent;
		}	
		
		LogChannel('Boat', "Rudder turn factor: " + turnFactor );
		
		
		rudderDamper = rudderDamper + dt * 6.f * ( turnFactor - rudderDamper );	
		LogChannel('Boat', "Rudder damper: " + rudderDamper );
		
		boatLogic.SetRudderDir( virtual_parent, rudderDamper );
		
		if( this.vehicleCombatMgr.IsInCombatAction() )
		{
			moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw );	
		}
		else
		{
			moveData.pivotRotationController.SetDesiredHeading( parent.GetHeading() - rudderDamper * 20.f );		
		}

		// SmartCamera - BEGIN
		if (SC_boatOnCameraTickPostTick(parent, boatComponent, camera, moveData, dt)) {
			return true;
		}
		// SmartCamera - END

		if( vehicleCombatMgr.OnGameCameraTick( moveData, dt ) )
		{
			return true;
		}
		
		theGame.GetGameCamera().ChangePivotDistanceController( 'Boat_DC' );
		theGame.GetGameCamera().ChangePivotRotationController( 'Boat_RC' );
		
		
		
		moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
		moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
		moveData.pivotPositionController = theGame.GetGameCamera().GetActivePivotPositionController();
		
		
		if( boatLogic.GameCameraTick( fovDistPitch, offsetZ, sailOffset, dt, false ) )
		{
			boatPPC = ( CCustomCameraBoatPPC )moveData.pivotPositionController;
			if( boatPPC )
			{
				offsetUp = Vector( 0.0f, 0.0f, offsetZ );
				boatPPC.SetPivotOffset( offsetUp );
			}

			moveData.pivotRotationController.SetDesiredPitch( fovDistPitch.Z );
			moveData.pivotDistanceController.SetDesiredDistance( fovDistPitch.Y );
			
			sailCameraOffset = boatLogic.GetSailTilt() * sailOffset;
			DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( sailCameraOffset, 0.f, 0.f ), 0.5f, dt );
		}
		
		return true;
	}
	
	event OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
	{
		if ( super.OnGameCameraPostTick( moveData, dt ) )
			return true;
	}
	
	
	
	
	
	function CanAccesFastTravel( target : W3FastTravelEntity ) : bool 
	{
		return target.canBeReachedByBoat;
	}
	
	public function TriggerDrowning()
	{
		if( vehicleCombatMgr )
		{
			vehicleCombatMgr.OnForceItemActionAbort();
		}
	}
}





state SailingPassive in CR4Player extends UseGenericVehicle
{
	private var boatLogic : CBoatComponent;
	private var dismountRequest : bool;
	private var vehicleCombatMgr : W3VehicleCombatManager;
	private var rudderDamper : float;
	
	default rudderDamper = 0.f;
	default dismountRequest = false;
	
	protected function Init()
	{
		super.Init();
		boatLogic = (CBoatComponent)vehicle;
	}
	
	event OnEnterState( prevStateName : name )
	{
		var commonMapManager : CCommonMapManager = theGame.GetCommonMapManager();
		
		super.OnEnterState(prevStateName);
		
		if( !vehicleCombatMgr )
		{
			vehicleCombatMgr = new W3VehicleCombatManager in this;
		}
	
		dismountRequest = false;
		
		vehicleCombatMgr.Setup( parent, vehicle );
		vehicleCombatMgr.GotoStateAuto();
		vehicle.SetCombatManager( vehicleCombatMgr );		
		
		ProcessBoatSailingPassive();
				
		theGame.GetGameCamera().SetAllowAutoRotation( false );
		commonMapManager.NotifyPlayerMountedBoat();
	}
	
	event OnLeaveState( nextStateName : name )
	{
		var commonMapManager : CCommonMapManager = theGame.GetCommonMapManager();
		
		super.OnLeaveState( nextStateName );
		theGame.GetGameCamera().SetAllowAutoRotation( true );
		commonMapManager.NotifyPlayerDismountedBoat();
	}	
	
	entry function ProcessBoatSailingPassive()
	{
		var axis : float;
		
		parent.EnableCollisions( false );
		
		
		theSound.SoundEvent( "boat_sail_temp_loop" );
		theSound.EnterGameState(ESGS_Boat);	
		parent.CreateAttachment( boatLogic.GetEntity(), 'seat_passenger' );	

		
		while( !dismountRequest )
		{
			FindTarget();
			Sleep( 0.2f );
		}
				
		parent.ClearCleanupFunction();
		
		((CPlayerStateDismountBoat)parent.GetState('DismountBoat')).SetupState( boatLogic, DT_normal );
		((CPlayerStateDismountBoat)parent.GetState('DismountBoat')).DismountFromPassenger( true );
		parent.GotoState( 'DismountBoat', true );
	}
	function DismountVehicle()
	{
		dismountRequest = true;
	}
	
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{
		var turnFactor  : float;
		var velocityRatio : float;		
		var sailCameraOffset : float;
		
		var fovDistPitch : Vector;
		var offsetZ : float;
		var offsetUp : Vector;
		var sailOffset : float;
		
		var boatPPC : CCustomCameraBoatPPC;
		
		parent.UpdateLookAtTarget();
		
		ShouldEnableBoatMusic();
		
		
		rudderDamper = rudderDamper + dt * 6.f * ( turnFactor - rudderDamper );	
		boatLogic.SetRudderDir( virtual_parent, rudderDamper );
		
		if ( this.vehicleCombatMgr.IsInCombatAction() )
		{
			moveData.pivotRotationController.minPitch = -55.f;
			moveData.pivotRotationController.maxPitch = theGame.GetGameplayConfigFloatValue( 'debugA' );
			moveData.pivotRotationController.SetDesiredHeading( moveData.pivotRotationValue.Yaw );
		}
		else
		{
			moveData.pivotRotationController.minPitch = -55.f;
			moveData.pivotRotationController.maxPitch = -3;
			moveData.pivotRotationController.SetDesiredHeading( parent.GetHeading() - rudderDamper * 20.f );
		}
		
		if( vehicleCombatMgr.OnGameCameraTick( moveData, dt ) )
		{
			return true;
		}
		
		theGame.GetGameCamera().ChangePivotDistanceController( 'Boat_DC' );
		theGame.GetGameCamera().ChangePivotRotationController( 'Boat_RC' );
		
		
		
		moveData.pivotRotationController = theGame.GetGameCamera().GetActivePivotRotationController();
		moveData.pivotDistanceController = theGame.GetGameCamera().GetActivePivotDistanceController();
		moveData.pivotPositionController = theGame.GetGameCamera().GetActivePivotPositionController();
		
		
		if( boatLogic.GameCameraTick( fovDistPitch, offsetZ, sailOffset, dt, true ) )
		{
			camera.fov = fovDistPitch.X;
			
			boatPPC = ( CCustomCameraBoatPPC )moveData.pivotPositionController;
			if( boatPPC )
			{
				offsetUp = Vector( 0.0f, 0.0f, offsetZ );
				boatPPC.SetPivotOffset( offsetUp );
			}

			moveData.pivotRotationController.SetDesiredPitch( fovDistPitch.Z );
			moveData.pivotDistanceController.SetDesiredDistance( fovDistPitch.Y );
			
			sailCameraOffset = boatLogic.GetSailTilt() * sailOffset;
			DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( sailCameraOffset, 0.f, 0.f ), 0.5f, dt );
		}
		
		return true;
	}
	
	event OnGameCameraPostTick( out moveData : SCameraMovementData, dt : float )
	{
		if ( super.OnGameCameraPostTick( moveData, dt ) )
			return true;
	}
	
	
	
}
