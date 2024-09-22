

public class Set extends ScriptableService {
    private let m_value: array<Variant>;
    public let m_mutex: RWLock;

    private cb func OnReload() {
        this.Clear();
    }

    public func Size() -> Int32 {
        RWLock.AcquireShared(this.m_mutex);
        let size = ArraySize(this.m_value);
        RWLock.ReleaseShared(this.m_mutex);
        return size;
    }

    public func Add(value: Variant) -> Void {
        if NotEquals(this.Has(value), true) {
            RWLock.Acquire(this.m_mutex);
            ArrayPush(this.m_value, value);
            RWLock.Release(this.m_mutex);
        }
    }

    public func Clear() -> Void {
        RWLock.Acquire(this.m_mutex);
        ArrayClear(this.m_value);
        RWLock.Release(this.m_mutex);
    }

    public func Delete(value: Variant) -> Bool {
        if Equals(this.Has(value), true) {
            RWLock.Acquire(this.m_mutex);
            let res = ArrayRemove(this.m_value, value);
            RWLock.Release(this.m_mutex);
            return res;
        }
        return false;
    }

    public func Has(value: Variant) -> Bool {
        RWLock.AcquireShared(this.m_mutex);
        for item in this.m_value {
            if Equals(item, value) {
                RWLock.ReleaseShared(this.m_mutex);
                return true;
            }
        }
        RWLock.ReleaseShared(this.m_mutex);
        return false;
    }
}

public class CNameUtils extends ScriptableService {
    private let m_lock: RWLock;

    public func ArrayConcat(value1: array<CName>, value2: array<CName>) -> array<CName> {
        let _newArray: array<CName> = [];
        RWLock.Acquire(this.m_lock);
        for value in value1 {
            ArrayPush(_newArray, value);
        }
        for value in value2 {
            ArrayPush(_newArray, value);
        }
        RWLock.Release(this.m_lock);
        return _newArray;
    }
}

class TagService extends ScriptableService {
    public func QuestFailedFact() -> CName {
        return n"mq_kidnap_failed";
    }

    public func GetPanamTag() -> CName {
        return n"mq_kidnap_panam";
    }

    public func GetTag() -> CName {
        return n"mq_kidnap";
    }

    public func GetHostileTag() -> CName {
        return n"mq_kidnap_hostile_tag";
    }

    public func GetSunsetTag() -> CName {
        return n"mq_sunset_tag";
    }

    public func GetEnemyDefeatedFact() -> CName {
        return n"kidnap_ambush_enemy_defeat";
    }

    public func GetShardOneReadFact() -> CName {
        return n"kidnap_shard_1_read";
    }

    public func GetShardTwoReadFact() -> CName {
        return n"kidnap_shard_2_read";
    }
}

class CoreService extends ScriptableService {
    private let m_panam_id: EntityID;
    private let m_sunset_dead_body: EntityID;
    private let core: ref<CoreSystem>;

    public func GetCore() -> ref<CoreSystem> {
        if Equals(IsDefined(this.core), false) {
            this.core = new CoreSystem();
        }
        return this.core;
    }

    public func SpawnPanam(pos: Vector4) -> Void {
        this.m_panam_id = this.GetCore().SpawnPanam(pos);
    }

    public func DespawnPanam() -> Void {
        GameInstance.GetDynamicEntitySystem().DeleteEntity(this.m_panam_id);
    }

    public func HandleAmbushPhase() -> Void {
        this.GetCore().HandleAmbushPhase();
    }

    public func SpawnDeadMaelstrom() -> Void {
        this.m_sunset_dead_body = this.GetCore().SpawnDeadMaelstrom();
    }
}

class PositionService extends ScriptableService {
    /* Panam spawn point after you released her */
    public func GetPanamSpawnPosition() -> Vector4 {
        return new Vector4(-1597.6438, 3039.146, 14.349998, 1);
    }

    /* ambush pos behind column */
    public func GetAmbushPositionBehindTheColumn() -> Vector4 {
        return new Vector4(-2032.0989, 2789.7456, 7.2045135, 1);
    }

    /* ladder second floor */
    public func GetAmbushPositionLadderSecondFloor() -> Vector4 {
        return new Vector4(-2033.9669, 2798.9858, 10.914497, 1);
    }

    /* ladder first floor */
    public func GetAmbushPositionLadderFirstFloor() -> Vector4 {
        return new Vector4(-2038.4323, 2801.943, 8.914497, 1);
    }

    /* behind ladder */
    public func GetAmbushPositionBehindLadder() -> Vector4 {
        return new Vector4(-2040.335, 2803.1807, 7.204506, 1);
    }

    /* on clif */
    public func GetAmbushPositionOnClifFirst() -> Vector4 {
        return new Vector4(-2047.6093, 2797.836, 13.419998, 1);
    }

    /* on clif */
    public func GetAmbushPositionOnClifSecond() -> Vector4 {
        return new Vector4(-2044.7811, 2801.8208, 13.419998, 1);
    }

    /* Next to Panam's car */
    public func GetSunsetDeadEnemyPosition() -> Vector4 {
        return new Vector4(1650.1475, -755.08655, 49.95764, 1);
    }
}

class CoreSystem extends ScriptableSystem {
    private let m_entitySystem: wref<DynamicEntitySystem>;
    private let m_callbackSystem: wref<CallbackSystem>;

    public func HasSpaceForSpawning() -> Bool {
        return !IsEntityInInteriorArea(this.GetPlayer()) && SpatialQueriesHelper.HasSpaceInFront(this.GetPlayer(), 0.1, 10.0, 10.0, 2.0);
    }

    public func GetPlayer() -> ref<PlayerPuppet> {
        return GetPlayer(GetGameInstance());
    }

    public func GetDirection(angle: Float) -> Vector4 {
        return Vector4
            .RotateAxis(
                this.GetPlayer().GetWorldForward(),
                new Vector4(0, 0, 1, 0),
                angle / 180.0 * Pi()
            );
    }

    public func GetPosition(distance: Float, angle: Float) -> Vector4 {
        return this.GetPlayer().GetWorldPosition() + this.GetDirection(angle) * distance;
    }

    public func GetOrientation(angle: Float) -> Quaternion {
        return EulerAngles.ToQuat(Vector4.ToRotation(this.GetDirection(angle)));
    }

    private func OnAttach() {
        this.m_entitySystem = GameInstance.GetDynamicEntitySystem();
        this.m_callbackSystem = GameInstance.GetCallbackSystem();
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        this
            .m_callbackSystem
            .RegisterCallback(n"Session/Ready", this, n"OnSessionReady");
        this
            .m_callbackSystem
            .RegisterCallback(n"Entity/Attached", this, n"OnEntityAttached")
            .AddTarget(DynamicEntityTarget.Tag(tagService.GetTag()));
        this
            .m_callbackSystem
            .RegisterCallback(n"Entity/Detach", this, n"OnEntityDetached")
            .AddTarget(DynamicEntityTarget.Tag(tagService.GetTag()));
    }

    public func Spawn(
        recordID: TweakDBID,
        position: Vector4,
        tags: array<CName>,
        appearance: CName
    ) -> EntityID {
        let utils = GameInstance.GetScriptableServiceContainer().GetService(n"CNameUtils") as CNameUtils;
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let npcTags: array<CName> = utils.ArrayConcat([tagService.GetTag()], tags);
        let npcSpec = new DynamicEntitySpec();
        npcSpec.recordID = recordID;
        npcSpec.appearanceName = appearance;
        npcSpec.position = position;
        npcSpec.orientation = this.GetOrientation(-45.0);
        npcSpec.persistState = false;
        npcSpec.persistSpawn = false;
        npcSpec.tags = npcTags;
        return GameInstance.GetDynamicEntitySystem().CreateEntity(npcSpec);
    }

    public func InjectLoot(id: EntityID, lootID: ItemID, quantity: Uint32, opt dynamicTags: array<CName>) -> Void {
        let container: ref<ContainerManager> = this.GetGameInstance().GetContainerManager();
        container.InjectLoot(id, lootID, quantity, dynamicTags);
    }

    public func SpawnPanam(pos: Vector4) -> EntityID {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let panamSpec = new DynamicEntitySpec();
        let orientation = this.GetOrientation(90.0);
        panamSpec.recordID = t"Character.Panam";
        panamSpec.appearanceName = n"panam_default_scars";
        panamSpec.orientation = orientation;
        panamSpec.position = pos;
        panamSpec.persistState = false;
        panamSpec.persistSpawn = false;
        panamSpec.tags = [tagService.GetTag(), tagService.GetPanamTag()];
        let system = GameInstance.GetDynamicEntitySystem();
        return system.CreateEntity(panamSpec);
    }

    public func HandlePanamSpawn(ent: ref<ScriptedPuppet>) -> Void {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        if Equals(ent.HasTag(tagService.GetPanamTag()), true) {
            let player = this.GetPlayer();
            let ref: EntityReference = CreateEntityReference(s"#player", []);
            let role = new AIFollowerRole();
            let component = ent.GetAIControllerComponent();
            let puppetAgent = ent.GetAttitudeAgent();
            let playerAgent = player.GetAttitudeAgent();
            role.followerRef = ref;
            role.SetFollowTarget(player);
            component.SetAIRole(role);
            component.OnAttach();
            puppetAgent.SetAttitudeGroup(playerAgent.GetAttitudeGroup());
            puppetAgent.SetAttitudeTowards(playerAgent, EAIAttitude.AIA_Friendly);
        }
    }

    public func SpawnDeadMaelstrom() -> EntityID {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let positionService = GameInstance.GetScriptableServiceContainer().GetService(n"PositionService") as PositionService;
        let tags = [tagService.GetTag(), tagService.GetSunsetTag()];
        let coords = positionService.GetSunsetDeadEnemyPosition();
        let npcSpec = new DynamicEntitySpec();
        npcSpec.recordID = t"Character.cpz_maelstrom_grunt2_melee2_machete_ma";
        npcSpec.appearanceName = n"random";
        npcSpec.position = coords;
        npcSpec.orientation = new Quaternion(0, 0, 0, 1);
        npcSpec.persistState = false;
        npcSpec.persistSpawn = false;
        npcSpec.tags = tags;
        return GameInstance.GetDynamicEntitySystem().CreateEntity(npcSpec);
    }

    private cb func OnEntityAttached(event: ref<EntityLifecycleEvent>) {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let ent = event.GetEntity() as ScriptedPuppet;
        let hash = EntityID.GetHash(event.GetEntity().GetEntityID());
        let tag = ent.HasTag(tagService.GetHostileTag());
        let sunsetTag = ent.HasTag(tagService.GetSunsetTag());
        FTLog(s"EntityAttached hash \(hash)");

        if IsDefined(ent) {
            this.HandlePanamSpawn(ent);
        }

        if Equals(sunsetTag, true) {
            ent.Kill();
        }

        if Equals(tag, true) {
            // Make it hostile
            let command = new AIInjectCombatThreatCommand();
            command.targetPuppetRef = CreateEntityReference(s"#player", []);
            command.duration = 200.0;
            AIComponent.SendCommand(ent, command);
        }
    }

    private cb func OnEntityDetached(event: ref<EntityLifecycleEvent>) {
        let hash = EntityID.GetHash(event.GetEntity().GetEntityID());
        FTLog(s"detached \(hash)");
    }

    // if Equals(hash, this.m_panam_hash) {
    //     SetFactValue(this.GetGameInstance(), this.QuestFailedFact(), 1);
    // }
    private cb func OnSessionReady(event: ref<GameSessionEvent>) -> Void {
        let _set = GameInstance.GetScriptableServiceContainer().GetService(n"Set") as Set;
        _set.Clear();
    }

    public func HandleAmbushPhase() {
        let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
        let positionService = GameInstance.GetScriptableServiceContainer().GetService(n"PositionService") as PositionService;
        let i = 0;
        let tags = [tagService.GetTag(), tagService.GetHostileTag()];
        let appearance = n"random";
        while i < 2 {
            this
                .Spawn(
                    t"Character.cpz_maelstrom_grunt2_melee2_machete_ma",
                    positionService.GetAmbushPositionBehindTheColumn(),
                    tags,
                    appearance
                );

            i += 1;
            this
                .Spawn(
                    t"Character.cpz_maelstrom_grunt2_ranged2_ajax_wa",
                    positionService.GetAmbushPositionLadderSecondFloor(),
                    tags,
                    appearance
                );
        }
        this
            .Spawn(
                t"Character.cpz_maelstrom_grunt2_ranged2_ajax_wa",
                positionService.GetAmbushPositionLadderFirstFloor(),
                tags,
                appearance
            );

        this
            .Spawn(
                t"Character.sq031_maelstrom_melee_female_elite",
                positionService.GetAmbushPositionBehindLadder(),
                tags,
                appearance
            );
        this
            .Spawn(
                t"Character.cpz_maelstrom_grunt2_ranged2_ajax_wa",
                positionService.GetAmbushPositionOnClifFirst(),
                tags,
                appearance
            );
        this
            .Spawn(
                t"Character.cpz_maelstrom_grunt2_ranged2_ajax_wa",
                positionService.GetAmbushPositionOnClifSecond(),
                tags,
                appearance
            );

        let effectTweakDBID: TweakDBID = t"BaseStatusEffect.Blind";
        let delay: Float = 0.25;
        let res = StatusEffectHelper.ApplyStatusEffect(this.GetPlayer(), effectTweakDBID, delay);
        LogChannel(n"DEBUG", s"Blind effect applied result \(res)");
    }
}

@wrapMethod(ScriptedPuppet)
protected cb func OnKillRewardEvent(evt: ref<KillRewardEvent>) {
    wrappedMethod(evt);
    let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
    let _set = GameInstance.GetScriptableServiceContainer().GetService(n"Set") as Set;
    let hastag = evt.victim.HasTag(tagService.GetTag());
    let hash = EntityID.GetHash(evt.victim.GetEntityID());
    let totalSize: Int32 = 8;

    if Equals(hastag, true) {
        _set.Add(hash);
        if Equals(_set.Size() >= totalSize, true) {
            let game = evt.victim.GetGame();
            let fact = tagService.GetEnemyDefeatedFact();
            SetFactValue(game, fact, 1);
        }
    }
}

@wrapMethod(ShardCaseContainer)
protected cb func OnInteraction(choiceEvent: ref<InteractionChoiceEvent>) -> Bool {
    let tagService = GameInstance.GetScriptableServiceContainer().GetService(n"TagService") as TagService;
    let currentReadedShardTweakID = this.itemTDBID;
    FTLog(s"On interact \(TDBID.ToStringDEBUG(currentReadedShardTweakID))");
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_1") {
        SetFactValue(this.GetGame(), tagService.GetShardOneReadFact(), 1);
    }
    if Equals(currentReadedShardTweakID, t"Items.mq_kidnap_shard_2") {
        SetFactValue(this.GetGame(), tagService.GetShardTwoReadFact(), 1);
    }
    let result: Bool = wrappedMethod(choiceEvent);
    return result;
}

@addMethod(PlayerPuppet)
protected cb func OnKidnapQuestEvent(event: ref<ActionEvent>) {
    let coreService = GameInstance.GetScriptableServiceContainer().GetService(n"CoreService") as CoreService;
    let positionService = GameInstance.GetScriptableServiceContainer().GetService(n"PositionService") as PositionService;
    let pos = this.GetWorldPosition();
    let orient = this.GetWorldOrientation();

    switch event.eventAction {
        case n"Activated":
            FTLog(s"\(this) | \(pos) | \(orient) | Quest Activated");
            break;
        case n"EnterSunset":
            FTLog(s"Entered Sunset. Spawn maelstrom");
            coreService.SpawnDeadMaelstrom();
            break;
        case n"Ambush":
            FTLog(s"Ambush phase");
            coreService.HandleAmbushPhase();
            break;
        case n"SavePanam":
            FTLog(s"Save Panam phase executed");
            coreService.SpawnPanam(positionService.GetPanamSpawnPosition());
            break;
        case n"OutPanam":
            coreService.DespawnPanam();
            FTLog(s"Despawn Panam");
            break;
        default:
            FTLog(s"\(event.eventAction)");
            break;
    }
}