
/*Dancing*/
@addField(PlayerPuppet)
public let device: ref<GameObject>;

@addMethod(PlayerPuppet)
public func ADance() -> Void {
    let tag = n"DanceMod";
    GameInstance.GetDynamicEntitySystem().RegisterListener(tag, this, n"OnEntityUpdate");
    let spec = new DynamicEntitySpec();
    spec.templatePath = r"base\\cyberscript\\entity\\workspot_anim.ent";
    spec.position = this.GetWorldPosition();
    spec.orientation = EulerAngles.ToQuat(Vector4.ToRotation(this.GetWorldPosition()));
    spec.tags = [tag];
    GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
}

@addMethod(PlayerPuppet)
public func AKiss() -> Void {
    let tag = n"DanceMod";
    GameInstance.GetDynamicEntitySystem().RegisterListener(tag, this, n"OnKiss");
    let spec = new DynamicEntitySpec();
    spec.templatePath = r"base\\cyberscript\\entity\\workspot_anim.ent";
    spec.position = this.GetWorldPosition();
    spec.orientation = EulerAngles.ToQuat(Vector4.ToRotation(this.GetWorldPosition()));
    spec.tags = [tag];
    GameInstance.GetDynamicEntitySystem().CreateEntity(spec);
}

@addMethod(PlayerPuppet)
private cb func OnKiss(event: ref<DynamicEntityEvent>) {
    if Equals(event.GetEventType(), DynamicEntityEventType.Spawned) {
        let device = GameInstance.GetDynamicEntitySystem().GetEntity(event.GetEntityID()) as GameObject;
        this.device = device;
        GameInstance.GetWorkspotSystem(this.GetGame()).PlayInDevice(device, this);
        GameInstance
            .GetWorkspotSystem(this.GetGame())
            .SendJumpToAnimEnt(this, n"q202__synced__player__stand_ground__hug__01", true);
    }
}

@addMethod(PlayerPuppet)
public func AStop() -> Void {
    GameInstance.GetWorkspotSystem(this.GetGame()).StopInDevice(this.device);
    GameInstance.GetWorkspotSystem(this.GetGame()).StopNpcInWorkspot(this);
    FTLog(s"this.device \(this.device)");
    GameInstance.GetDynamicEntitySystem().DeleteEntity(this.device.GetEntityID());
    this.device = null;
}

/* DEBUGGING */
@addField(PlayerPuppet)
public let _panam_id: EntityID;

@addMethod(PlayerPuppet)
public func ASpawnPanam() -> Void {
    let tag = n"Panam_DEBUG";
    let system: ref<DynamicEntitySystem> = GameInstance.GetDynamicEntitySystem();
    let callbackSystem: ref<CallbackSystem> = GameInstance.GetCallbackSystem();

    callbackSystem
        .RegisterCallback(n"Entity/Attached", this, n"OnSpawnPanam")
        .AddTarget(DynamicEntityTarget.Tag(tag));

    callbackSystem
        .RegisterCallback(n"Entity/Detached", this, n"OnSpawnPanamDespawn")
        .AddTarget(DynamicEntityTarget.Tag(tag));

    let spec = new DynamicEntitySpec();
    spec.recordID = t"Character.Panam";
    spec.position = this.GetWorldPosition();
    spec.orientation = EulerAngles.ToQuat(Vector4.ToRotation(this.GetWorldPosition()));
    spec.tags = [tag, n"#panam"];
    this._panam_id = system.CreateEntity(spec);
}

@addMethod(PlayerPuppet)
private cb func OnSpawnPanamDespawn(event: ref<EntityLifecycleEvent>) {
    FTLog(s"Panam Despawned");
}

@addMethod(PlayerPuppet)
private cb func OnSpawnPanam(event: ref<EntityLifecycleEvent>) {
    let ent = event.GetEntity() as ScriptedPuppet;
    if IsDefined(ent) {
        if Equals(ent.HasTag(n"Panam_DEBUG"), true) {
            FTLog(s"Panam spawned \(this._panam_id)");
            let ref: EntityReference = CreateEntityReference(s"#player", []);
            let role = new AIFollowerRole();
            let component = ent.GetAIControllerComponent();
            let puppetAgent = ent.GetAttitudeAgent();
            let playerAgent = this.GetAttitudeAgent();
            role.followerRef = ref;
            role.SetFollowTarget(this);
            component.SetAIRole(role);
            component.OnAttach();
            puppetAgent.SetAttitudeGroup(playerAgent.GetAttitudeGroup());
            puppetAgent.SetAttitudeTowards(playerAgent, EAIAttitude.AIA_Friendly);
        }
    }
}

@addMethod(PlayerPuppet)
private cb func ADespawnPanam() {
    GameInstance.GetDynamicEntitySystem().DeleteEntity(this._panam_id);
}

@wrapMethod(MinimapContainerController)
protected cb func OnPlayerEnterArea(controller: wref<MinimapSecurityAreaMappinController>) -> Bool {
    let area = controller.area;
    let mappin = controller.GetMappin();
    FTLog(s"area \(area) mappin \(mappin)");
    let result: Bool = wrappedMethod(controller);

    return result;
}

@wrapMethod(MinimapContainerController)
protected cb func OnPlayerAttach(player: ref<GameObject>) -> Bool {
    FTLog(s"OnPlayerAttach MinimapContainerController");
    let result: Bool = wrappedMethod(player);

    return result;
}
