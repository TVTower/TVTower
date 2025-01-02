SuperStrict
Import "Dig/base.util.event.bmx"

Global GameEventKeys:TGameEventKeys = New TGameEventKeys

Type TGameEventKeys
	'common.misc.screen.bmx"
	Field Screen_onTryEnter:TEventKey = GetEventKey("screen.onTryEnter", True)
	Field Screen_onBeginEnter:TEventKey = GetEventKey("screen.onBeginEnter", True)
	Field Screen_onFinishEnter:TEventKey = GetEventKey("screen.onFinishEnter", True)
	Field Screen_onLeave:TEventKey = GetEventKey("screen.onLeave", True)
	Field Screen_onTryLeave:TEventKey = GetEventKey("screen.onTryLeave", True)
	Field Screen_onBeginLeave:TEventKey = GetEventKey("screen.onBeginLeave", True)
	Field Screen_onFinishLeave:TEventKey = GetEventKey("screen.onFinishLeave", True)
	Field Screen_OnSetCurrent:TEventKey = GetEventKey("screen.onSetCurrent", True)
	Field Screen_OnUpdate:TEventKey = GetEventKey("screen.onUpdate", True)
	Field Screen_OnDraw:TEventKey = GetEventKey("screen.onDraw", True)

	'game.achievements.base.bmx
	Field Achievement_OnComplete:TEventKey = GetEventKey("Achievement.OnComplete", True)
	Field Achievement_OnFail:TEventKey = GetEventKey("Achievement.OnFail", True)
	Field AchievementTask_OnComplete:TEventKey = GetEventKey("AchievementTask.OnComplete", True)
	Field AchievementTask_OnFail:TEventKey = GetEventKey("AchievementTask.OnFail", True)
	Field AchievementReward_OnBeginGiveToPlayer:TEventKey = GetEventKey("AchievementReward.OnBeginGiveToPlayer", True)
	Field AchievementReward_OnGiveToPlayer:TEventKey = GetEventKey("AchievementReward.OnGiveToPlayer", True)
	

	'game.ai.bmx
	'this is the same as in GUIEventKeys!
	Field Chat_OnAddEntry:TEventKey = GetEventKey("Chat.onAddEntry", True)	

	'game.archivedmessages.bmx
	Field ArchivedMessageCollection_onAdd:TEventKey = GetEventKey("ArchivedMessageCollection.onAdd", True)
	Field ArchivedMessageCollection_onRemove:TEventKey = GetEventKey("ArchivedMessageCollection.onRemove", True)

	'game.award.base.bmx
	Field Award_OnFinish:TEventKey = GetEventKey("Award.OnFinish", True)

	'game.betty.bmx
	Field Betty_OnAdjustLove:TEventKey = GetEventKey("Betty_OnAdjustLove.Betty_OnAdjustLove", True)

	'game.broadcastmaterial.advertisement.bmx
	Field Broadcast_Advertisement_BeginBroadcasting:TEventKey = GetEventKey("broadcast.advertisement.BeginBroadcasting", True)
	Field Broadcast_Advertisement_BeginBroadcastingAsProgramme:TEventKey = GetEventKey("broadcast.advertisement.BeginBroadcastingAsProgramme", True)
	Field Broadcast_Advertisement_FinishBroadcastingAsProgramme:TEventKey = GetEventKey("broadcast.advertisement.FinishBroadcastingAsProgramme", True)
	Field Broadcast_Advertisement_FinishBroadcasting:TEventKey = GetEventKey("broadcast.advertisement.FinishBroadcasting", True)
	'game.broadcastmaterial.news.bmx
	Field Broadcast_Newsshow_BeforeBeginBroadcasting:TEventKey = GetEventKey("broadcast.newsshow.BeforeBeginBroadcasting", True)
	Field Broadcast_Newsshow_BeginBroadcasting:TEventKey = GetEventKey("broadcast.newsshow.BeginBroadcasting", True)
	Field Broadcast_Newsshow_BeforeFinishBroadcasting:TEventKey = GetEventKey("broadcast.newsshow.BeforeFinishBroadcasting", True)
	Field Broadcast_Newsshow_FinishBroadcasting:TEventKey = GetEventKey("broadcast.newsshow.FinishBroadcasting", True)
	'game.broadcastmaterial.programme.bmx
	Field Broadcast_Programme_FinishBroadcasting:TEventKey = GetEventKey("broadcast.programme.FinishBroadcasting", True)
	Field Broadcast_Programme_FinishBroadcastingAsAdvertisement:TEventKey = GetEventKey("broadcast.programme.FinishBroadcastingAsAdvertisement", True)
	Field Broadcast_Programme_BeginBroadcasting:TEventKey = GetEventKey("broadcast.programme.BeginBroadcasting", True)
	Field Broadcast_Programme_BeginBroadcastingAsAdvertisement:TEventKey = GetEventKey("broadcast.programme.BeginBroadcastingAsAdvertisement", True)

	'game.game.bmx:
	Field Game_OnYear:TEventKey = GetEventKey("Game.onYear", True)
	Field Game_OnDay:TEventKey = GetEventKey("Game.onDay", True)
	Field Game_OnHour:TEventKey = GetEventKey("Game.onHour", True)
	Field Game_OnMinute:TEventKey = GetEventKey("Game.onMinute", True)
	Field Game_OnRealTimeSecond:TEventKey = GetEventKey("Game.OnRealTimeSecond", True)
	Field Game_OnStart:TEventKey = GetEventKey("Game.onStart", True)
	Field Game_OnBegin:TEventKey = GetEventKey("Game.onBegin", True)
	Field Game_OnPause:TEventKey = GetEventKey("Game.onPause", True)
	Field Game_OnResume:TEventKey = GetEventKey("Game.onResume", True)
	Field Game_SetPlayerBankruptLevel:TEventKey = GetEventKey("Game.SetPlayerBankruptLevel", True)
	Field Game_SetPlayerBankruptBegin:TEventKey = GetEventKey("Game.SetPlayerBankruptBegin", True)
	Field Game_SetPlayerBankruptFinish:TEventKey = GetEventKey("Game.SetPlayerBankruptFinish", True)
	Field Game_OnStartPlayer:TEventKey = GetEventKey("Game.OnStartPlayer", True)
	Field Game_PreparePlayer:TEventKey = GetEventKey("Game.PreparePlayer", True)
	Field Game_OnSetActivePlayer:TEventKey = GetEventKey("Game.onSetActivePlayer", True)


	'game.figure.base.bmx:
	Global Figure_OnSetHasMasterkey:TEventKey = EventManager.GetEventKey("Figure.OnSetHasMasterkey", True)
	Global Figure_OnChangeTarget:TEventKey = EventManager.GetEventKey("Figure.OnChangeTarget", True)
	Global Figure_OnBeginReachTarget:TEventKey = EventManager.GetEventKey("Figure.OnBeginReachTarget", True)
	Global Figure_OnReachTarget:TEventKey = EventManager.GetEventKey("Figure.OnReachTarget", True)
	Global Figure_OnEnterTarget:TEventKey = EventManager.GetEventKey("Figure.OnEnterTarget", True)

	'game.figure.bmx
	Field Figure_SetInRoom:TEventKey = GetEventKey("Figure.SetInRoom", True)
	Field Room_KickFigure:TEventKey = GetEventKey("Room.KickFigure", True)
	Field Figure_OnEnterRoom:TEventKey = GetEventKey("Figure.onEnterRoom", True)
	Field Figure_OnTryEnterRoom:TEventKey = GetEventKey("Figure.onTryEnterRoom", True)
	Field Figure_OnBeginEnterRoom:TEventKey = GetEventKey("Figure.onBeginEnterRoom", True)
	Field Figure_OnFinishEnterRoom:TEventKey = GetEventKey("Figure.onFinishEnterRoom", True)
	Field Figure_OnFailEnterRoom:TEventKey = GetEventKey("Figure.onFailEnterRoom", True)
	Field Figure_OnTryLeaveRoom:TEventKey = GetEventKey("Figure.onTryLeaveRoom", True)
	Field Figure_OnBeginLeaveRoom:TEventKey = GetEventKey("Figure.onBeginLeaveRoom", True)
	Field Figure_OnFinishLeaveRoom:TEventKey = GetEventKey("Figure.onFinishLeaveRoom", True)
	Field Figure_OnSyncTimer:TEventKey = GetEventKey("Figure.onSyncTimer", True)
	Field Figure_OnLeaveRoom:TEventKey = GetEventKey("Figure.onLeaveRoom", True)
	Field Figure_OnForcefullyLeaveRoom:TEventKey = GetEventKey("Figure.onForcefullyLeaveRoom", True)

	'game.figure.customfigures.bmx:
	Field PublicAuthorities_OnConfiscateProgrammeLicence:TEventKey = GetEventKey("PublicAuthorities.onConfiscateProgrammeLicence", True)

	'game.stationmap.bmx:
	Field StationMapCollection_AddSection:TEventKey = GetEventKey("StationMapCollection.AddSection", True)
	Field StationMapCollection_AddCableNetwork:TEventKey = GetEventKey("StationMapCollection.AddCableNetwork", True)
	Field StationMapCollection_RemoveCableNetwork:TEventKey = GetEventKey("StationMapCollection.RemoveCableNetwork", True)
	Field StationMapCollection_AddSatellite:TEventKey = GetEventKey("StationMapCollection.AddSatellite", True)
	Field StationMapCollection_RemoveSatellite:TEventKey = GetEventKey("StationMapCollection.RemoveSatellite", True)
	Field StationMapCollection_LaunchSatellite:TEventKey = GetEventKey("StationMapCollection.LaunchSatellite", True)
	Field StationMapCollection_LetDieSatellite:TEventKey = GetEventKey("StationMapCollection.LetDieSatellite", True)
	Field StationMap_OnRecalculateAudienceSum:TEventKey = GetEventKey("StationMap.OnRecalculateAudienceSum", True)
	Field StationMap_OnChangeReachLevel:TEventKey = GetEventKey("StationMap.OnChangeReachLevel", True)
	Field StationMap_AddStation:TEventKey = GetEventKey("StationMap.AddStation", True)
	Field StationMap_OnTrySellLastStation:TEventKey = GetEventKey("StationMap.OnTrySellLastStation", True)
	Field StationMap_RemoveStation:TEventKey = GetEventKey("StationMap.RemoveStation", True)
	Field Station_OnSetActive:TEventKey = GetEventKey("Station.OnSetActive", True)
	Field Station_OnSetInactive:TEventKey = GetEventKey("Station.OnSetInactive", True)
	Field Station_OnShutdown:TEventKey = GetEventKey("Station.OnShutdown", True)
	Field Station_OnResume:TEventKey = GetEventKey("Station.OnResume", True)
	Field Station_OnContractEndsSoon:TEventKey = GetEventKey("Station.OnContractEndsSoon", True)
	Field BroadcastProvider_OnLaunch:TEventKey = GetEventKey("BroadcastProvider.OnLaunch", True)
	Field BroadcastProvider_OnSetActive:TEventKey = GetEventKey("BroadcastProvider.OnSetActive", True)
	Field BroadcastProvider_OnSetInactive:TEventKey = GetEventKey("BroadcastProvider.OnSetInactive", True)
	Field Satellite_OnUpgradeTech:TEventKey = GetEventKey("Satellite.OnUpgradeTech", True)
	
	
	'game.misc.ingamehelp.bmx"
	Field InGameHelp_ShowHelpWindow:TEventKey = GetEventKey("InGameHelp.ShowHelpWindow", True)
	Field InGameHelp_CloseHelpWindow:TEventKey = GetEventKey("InGameHelp.CloseHelpWindow", True)
	Field InGameHelp_ClosedHelpWindow:TEventKey = GetEventKey("InGameHelp.ClosedHelpWindow", True)

	'game.mission.bmx
	Field Mission_Achieved:TEventKey = GetEventKey("Mission.Achieved", True)
	Field Mission_Failed:TEventKey = GetEventKey("Mission.Failed", True)

	'game.network.networkhelper.bmx
	Field Network_InfoChannel_OnReceiveAnnounceGame:TEventKey = GetEventKey("Network.InfoChannel.onReceiveAnnounceGame", True)


	'game.newsagency.sports.bmx
	Field Sport_Playoffs_RunMatch:TEventKey = GetEventKey("Sport.Playoffs.RunMatch", True)
	Field Sport_StartPlayoffs:TEventKey = GetEventKey("Sport.StartPlayoffs", True)
	Field Sport_FinishPlayoffs:TEventKey = GetEventKey("Sport.FinishPlayoffs", True)
	Field Sport_StartSeason:TEventKey = GetEventKey("Sport.StartSeason", True)
	Field Sport_FinishSeason:TEventKey = GetEventKey("Sport.FinishSeason", True)
	Field Sport_AddLeague:TEventKey = GetEventKey("Sport.AddLeague", True)
	Field SportLeague_FinishMatchGroup:TEventKey = GetEventKey("SportLeague.FinishMatchGroup", True)
	Field SportLeague_StartSeason:TEventKey = GetEventKey("SportLeague.StartSeason", True)
	Field SportLeague_FinishSeason:TEventKey = GetEventKey("SportLeague.FinishSeason", True)
	Field SportLeague_StartSeasonPart:TEventKey = GetEventKey("SportLeague.StartSeasonPart", True)
	Field SportLeague_FinishSeasonPart:TEventKey = GetEventKey("SportLeague.FinishSeasonPart", True)
	Field SportLeague_RunMatch:TEventKey = GetEventKey("SportLeague.RunMatch", True)
	
	
	'game.person.base.bmx
	Field PersonBase_OnStartProduction:TEventKey = GetEventKey("PersonBase.OnStartProduction", True)
	Field PersonBase_OnFinishProduction:TEventKey = GetEventKey("PersonBase.OnFinishProduction", True)
	
	
	'game.player.bmx
	Field player_SetNewsAbonnement:TEventKey = GetEventKey("Player.SetNewsAbonnement", True)
	Field player_OnReachTarget:TEventKey = GetEventKey("Player.onReachTarget", True)
	Field player_OnReachRoom:TEventKey = GetEventKey("Player.onReachRoom", True)
	Field player_OnLeaveRoom:TEventKey = GetEventKey("Player.onLeaveRoom", True)
	Field player_OnBeginEnterRoom:TEventKey = GetEventKey("Player.onBeginEnterRoom", True)
	Field player_OnEnterRoom:TEventKey = GetEventKey("Player.onEnterRoom", True)

	'game.player.programmecollection.bmx
	Field ProgrammeCollection_removeAdContract:TEventKey = GetEventKey("ProgrammeCollection.removeAdContract", True)
	Field ProgrammeCollection_addAdContract:TEventKey = GetEventKey("ProgrammeCollection.addAdContract", True)
	Field ProgrammeCollection_addUnsignedAdContractToSuitcase:TEventKey = GetEventKey("ProgrammeCollection.addUnsignedAdContractToSuitcase", True)
	Field ProgrammeCollection_removeUnsignedAdContractFromSuitcase:TEventKey = GetEventKey("ProgrammeCollection.removeUnsignedAdContractFromSuitcase", True)
	Field ProgrammeCollection_addProgrammeLicenceToSuitcase:TEventKey = GetEventKey("ProgrammeCollection.addProgrammeLicenceToSuitcase", True)
	Field ProgrammeCollection_removeProgrammeLicenceFromSuitcase:TEventKey = GetEventKey("ProgrammeCollection.removeProgrammeLicenceFromSuitcase", True)
	Field ProgrammeCollection_removeProgrammeLicence:TEventKey = GetEventKey("ProgrammeCollection.removeProgrammeLicence", True)
	Field ProgrammeCollection_addProgrammeLicence:TEventKey = GetEventKey("ProgrammeCollection.addProgrammeLicence", True)
	Field ProgrammeCollection_moveScript:TEventKey = GetEventKey("ProgrammeCollection.moveScript", True)
	Field ProgrammeCollection_MoveScriptFromArchiveToSuitcase:TEventKey = GetEventKey("ProgrammeCollection.MoveScriptFromArchiveToSuitcase", True)
	Field ProgrammeCollection_MoveScriptFromSuitcaseToArchive:TEventKey = GetEventKey("ProgrammeCollection.MoveScriptFromSuitcaseToArchive", True)
	Field ProgrammeCollection_MoveScriptFromStudioToSuitcase:TEventKey = GetEventKey("ProgrammeCollection.MoveScriptFromStudioToSuitcase", True)
	Field ProgrammeCollection_MoveScriptFromSuitcaseToStudio:TEventKey = GetEventKey("ProgrammeCollection.MoveScriptFromSuitcaseToStudio", True)
	Field ProgrammeCollection_MoveScriptFromStudioToArchive:TEventKey = GetEventKey("ProgrammeCollection.MoveScriptFromStudioToArchive", True)
	Field ProgrammeCollection_addScriptToSuitcase:TEventKey = GetEventKey("ProgrammeCollection.addScriptToSuitcase", True)
	Field ProgrammeCollection_removeScriptFromSuitcase:TEventKey = GetEventKey("ProgrammeCollection.removeScriptFromSuitcase", True)
	Field ProgrammeCollection_removeScript:TEventKey = GetEventKey("ProgrammeCollection.removeScript", True)
	Field ProgrammeCollection_addScript:TEventKey = GetEventKey("ProgrammeCollection.addScript", True)
	Field ProgrammeCollection_onCreateProductionConceptFailed:TEventKey = GetEventKey("ProgrammeCollection.onCreateProductionConceptFailed", True)
	Field ProgrammeCollection_addProductionConcept:TEventKey = GetEventKey("ProgrammeCollection.addProductionConcept", True)
	Field ProgrammeCollection_destroyProductionConcept:TEventKey = GetEventKey("ProgrammeCollection.destroyProductionConcept", True)
	Field ProgrammeCollection_removeProductionConcept:TEventKey = GetEventKey("ProgrammeCollection.removeProductionConcept", True)
	Field ProgrammeCollection_addNews:TEventKey = GetEventKey("ProgrammeCollection.addNews", True)
	Field ProgrammeCollection_removeNews:TEventKey = GetEventKey("ProgrammeCollection.removeNews", True)

	'game.player.programmeplan.bmx
	Field ProgrammePlan_AddObject:TEventKey = GetEventKey("ProgrammePlan.AddObject", True)
	Field ProgrammePlan_RemoveObject:TEventKey = GetEventKey("ProgrammePlan.RemoveObject", True)
	Field ProgrammePlan_RemoveObjectInstances:TEventKey = GetEventKey("ProgrammePlan.RemoveObjectInstances", True)
	Field ProgrammePlan_SetNews:TEventKey = GetEventKey("ProgrammePlan.SetNews", True)
	Field ProgrammePlan_RemoveNews:TEventKey = GetEventKey("ProgrammePlan.RemoveNews", True)
	Field ProgrammePlan_AddProgramme:TEventKey = GetEventKey("ProgrammePlan.AddProgramme", True)
	Field ProgrammePlan_RemoveProgramme:TEventKey = GetEventKey("ProgrammePlan.RemoveProgramme", True)
	Field ProgrammePlan_AddAdvertisement:TEventKey = GetEventKey("ProgrammePlan.AddAdvertisement", True)
	Field ProgrammePlan_RemoveAdvertisement:TEventKey = GetEventKey("ProgrammePlan.RemoveAdvertisement", True)

	Field Broadcast_common_BeginBroadcasting:TEventKey = GetEventKey("Broadcast.common.BeginBroadcasting", True)
	Field Broadcast_common_ContinueBroadcasting:TEventKey = GetEventKey("Broadcast.common.ContinueBroadcasting", True)
	Field Broadcast_common_FinishBroadcasting:TEventKey = GetEventKey("Broadcast.common.FinishBroadcasting", True)
	Field Broadcast_common_BreakBroadcasting:TEventKey = GetEventKey("Broadcast.common.BreakBroadcasting", True)
	Field ProgrammeLicence_ExceedingBroadcastLimit:TEventKey = GetEventKey("ProgrammeLicence.ExceedingBroadcastLimit", True)
	
	'game.player.boss.bmx
	Field PlayerBoss_onCallPlayer:TEventKey = GetEventKey("playerboss.onCallPlayer", True)
	Field PlayerBoss_onCallPlayerForced:TEventKey = GetEventKey("playerboss.onCallPlayerForced", True)
	Field PlayerBoss_onPlayerRepaysCredit:TEventKey = GetEventKey("playerboss.onPlayerRepaysCredit", True)
	Field PlayerBoss_onPlayerTakesCredit:TEventKey = GetEventKey("playerboss.onPlayerTakesCredit", True)
	Field PlayerBoss_onPlayerEnterBossRoom:TEventKey = GetEventKey("playerboss.onPlayerEnterBossRoom", True)

	'game.player.finance.bmx
	Global PlayerFinance_OnChangeMoney:TEventKey = GetEventKey("PlayerFinance.onChangeMoney", True)
	Global PlayerFinance_OnTransactionFailed:TEventKey = GetEventKey("PlayerFinance.OnTransactionFailed", True)

	'game.programme.programmelicence.bmx
	Field ProgrammeLicenceCollection_OnAddLicence:TEventKey = GetEventKey("ProgrammeLicenceCollection.onAddLicence", True)
	Field ProgrammeLicence_OnGiveBackToLicencePool:TEventKey = GetEventKey("ProgrammeLicence.onGiveBackToLicencePool", True)
	Field ProgrammeLicence_OnSetOwner:TEventKey = GetEventKey("ProgrammeLicence.onSetOwner", True)

	'game.publicimage.bmx
	Field PublicImage_OnChange:TEventKey = GetEventKey("PublicImage.onChange", True)

	'game.room.base.bmx"
	Field Room_OnBeginEnter:TEventKey = GetEventKey("Room.onBeginEnter", True)
	Field Room_OnFinishEnter:TEventKey = GetEventKey("Room.onFinishEnter", True)
	Field Room_OnBeginLeave:TEventKey = GetEventKey("Room.onBeginLeave", True)
	Field Room_OnFinishLeave:TEventKey = GetEventKey("Room.onFinishLeave", True)
	Field Room_OnBeginRental:TEventKey = GetEventKey("Room.onBeginRental", True)
	Field Room_OnCancelRental:TEventKey = GetEventKey("Room.onCancelRental", True)
	Field Room_OnBombExplosion:TEventKey = GetEventKey("Room.onBombExplosion", True)
	Field Room_OnMarshalVisit:TEventKey = GetEventKey("Room.onMarshalVisit", True)
	Field Room_OnRenovation:TEventKey = GetEventKey("Room.onRenovation", True)
	Field Room_OnSetBlocked:TEventKey = GetEventKey("Room.onSetBlocked", True)
	Field Room_OnChangeOwner:TEventKey = GetEventKey("Room.onChangeOwner", True)
	Field Room_OnDraw:TEventKey = GetEventKey("Room.onDraw", True)
	Field Room_OnUpdate:TEventKey = GetEventKey("Room.onUpdate", True)
	Field Room_OnUpdateDone:TEventKey = GetEventKey("Room.onUpdateDone", True)
	'game.room.bmx"
	Field Room_OnScreenDraw:TEventKey = GetEventKey("Room.onScreenDraw", True)
	Field Room_OnScreenUpdate:TEventKey = GetEventKey("Room.onScreenUpdate", True)

	'game.programme.adcontract.bmx
	Field AdContract_OnSetSpotsSent:TEventKey = GetEventKey("AdContract.onSetSpotsSent", True)
	Field AdContract_OnFail:TEventKey = GetEventKey("AdContract.onFail", True)
	Field AdContract_OnFinish:TEventKey = GetEventKey("AdContract.onFinish", True)
	
	Field NewsEvent_OnHappen:TEventKey = GetEventKey("NewsEvent.onHappen", True)
	
	'game.production.bmx
	Field Production_Start:TEventKey = GetEventKey("Production.start", True)
	Field Production_Abort:TEventKey = GetEventKey("Production.abort", True)
	Field Production_FinishPreproduction:TEventKey = GetEventKey("Production.finishPreproduction", True)
	Field Production_Finalize:TEventKey = GetEventKey("Production.finalize", True)

	'game.production.script.bmx
	Field Script_OnGiveBackToScriptPool:TEventKey = GetEventKey("Script.onGiveBackToScriptPool", True)

	'game.production.productioncompany.bmx
	Field ProductionCompany_OnChangeLevel:TEventKey = GetEventKey("ProductionCompany.OnChangeLevel", True)
	Field ProductionCompany_OnChangeXP:TEventKey = GetEventKey("ProductionCompany.OnChangeXP", True)

	'game.production.productionconcept.bmx
	Field ProductionConcept_SetScript:TEventKey = GetEventKey("ProductionConcept.SetScript", True)
	Field ProductionConcept_SetProductionCompany:TEventKey = GetEventKey("ProductionConcept.SetProductionCompany", True)
	Field ProductionConcept_SetCast:TEventKey = GetEventKey("ProductionConcept.SetCast", True)
	Field ProductionConcept_SetProductionFocus:TEventKey = GetEventKey("ProductionConcept.SetProductionFocus", True)
	Field ProductionFocus_SetFocus:TEventKey = GetEventKey("ProductionFocus.SetFocus", True)

	'game.roomhandler.adagency.bmx
	Field AdAgency_AddAdContract:TEventKey = GetEventKey("AdAgency.addAdContract", True)
	Field AdAgency_RemoveAdContract:TEventKey = GetEventKey("AdAgency.RemoveAdContract", True)

	'game.roomhandler.movieagency.bmx
	Field ProgrammeLicenceAuction_Refill:TEventKey = GetEventKey("ProgrammeLicenceAuction.Refill", True)
	Field ProgrammeLicenceAuction_OnWin:TEventKey = GetEventKey("ProgrammeLicenceAuction.onWin", True)
	Field ProgrammeLicenceAuction_OnEndAuction:TEventKey = GetEventKey("ProgrammeLicenceAuction.onEndAuction", True)
	Field ProgrammeLicenceAuction_OnGetOutbid:TEventKey = GetEventKey("ProgrammeLicenceAuction.onGetOutbid", True)
	Field ProgrammeLicenceAuction_SetBid:TEventKey = GetEventKey("ProgrammeLicenceAuction.setBid", True)
	
	'main.bmx
	Field App_OnSystemUpdate:TEventKey = GetEventKey("App.onSystemUpdate", True)
	Field App_OnSetLanguage:TEventKey = GetEventKey("App.onSetLanguage", True)
	Field App_OnUpdate:TEventKey = GetEventKey("App.onUpdate", True)
	Field App_OnDraw:TEventKey = GetEventKey("App.onDraw", True)
	Field App_OnStart:TEventKey = GetEventKey("App.onStart", True)
	Field App_OnLowPriorityUpdate:TEventKey = GetEventKey("App.OnLowPriorityUpdate", True)

	Field SaveGame_OnBeginLoad:TEventKey = GetEventKey("SaveGame.OnBeginLoad", True)
	Field SaveGame_OnLoad:TEventKey = GetEventKey("SaveGame.OnLoad", True)
	Field SaveGame_OnBeginSave:TEventKey = GetEventKey("SaveGame.OnBeginSave", True)
	Field SaveGame_OnSave:TEventKey = GetEventKey("SaveGame.OnSave", True)
	Field PublicAuthorities_onStartConfiscateProgramme:TEventKey = GetEventKey("publicAuthorities.onStartConfiscateProgramme", True)
	Field PublicAuthorities_onStopXRatedBroadcast:TEventKey = GetEventKey("publicAuthorities.onStopXRatedBroadcast", True)
	Field Broadcasting_BeforeStartAllNewsShowBroadcasts:TEventKey = GetEventKey("broadcasting.BeforeStartAllNewsShowBroadcasts", True)
	Field Broadcasting_BeforeFinishAllNewsShowBroadcasts:TEventKey = GetEventKey("broadcasting.BeforeFinishAllNewsShowBroadcasts", True)
	Field Broadcasting_BeforeStartAllProgrammeBlockBroadcasts:TEventKey = GetEventKey("broadcasting.BeforeStartAllProgrammeBlockBroadcasts", True)
	Field Broadcasting_BeforeFinishAllProgrammeBlockBroadcasts:TEventKey = GetEventKey("broadcasting.BeforeFinishAllProgrammeBlockBroadcasts", True)
	Field Broadcasting_BeforeStartAllAdBlockBroadcasts:TEventKey = GetEventKey("broadcasting.BeforeStartAllAdBlockBroadcasts", True)
	Field Broadcasting_BeforeFinishAllAdBlockBroadcasts:TEventKey = GetEventKey("broadcasting.BeforeFinishAllAdBlockBroadcasts", True)
	Field Broadcasting_AfterStartAllNewsShowBroadcasts:TEventKey = GetEventKey("broadcasting.AfterStartAllNewsShowBroadcasts", True)
	Field Broadcasting_AfterFinishAllNewsShowBroadcasts:TEventKey = GetEventKey("broadcasting.AfterFinishAllNewsShowBroadcasts", True)
	Field Broadcasting_AfterStartAllProgrammeBlockBroadcasts:TEventKey = GetEventKey("broadcasting.AfterStartAllProgrammeBlockBroadcasts", True)
	Field Broadcasting_AfterFinishAllProgrammeBlockBroadcasts:TEventKey = GetEventKey("broadcasting.AfterFinishAllProgrammeBlockBroadcasts", True)
	Field Broadcasting_AfterStartAllAdBlockBroadcasts:TEventKey = GetEventKey("broadcasting.AfterStartAllAdBlockBroadcasts", True)
	Field Broadcasting_AfterFinishAllAdBlockBroadcasts:TEventKey = GetEventKey("broadcasting.AfterFinishAllAdBlockBroadcasts", True)
End Type
