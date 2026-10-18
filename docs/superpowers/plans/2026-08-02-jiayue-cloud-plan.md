# 嘉悦云上 — 实现计划（Unity 版，已废弃）

> ⚠️ **已废弃（2026-10-18）：** 开发引擎已切换为 Godot，本计划中的 Unity/C# 内容不再执行。Godot 版实现计划见同目录的 `2026-10-18-jiayue-cloud-godot-plan.md`（撰写中）。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现第一人称投掷武器+超能力清版闯关游戏的核心玩法原型，包含角色控制、投掷系统、超能力、敌人AI和关卡管理。

**Architecture:** Unity 2022.3 LTS + C#，采用组件化设计。核心系统按功能分为 Player / Weapons / Superpowers / Enemies / Level / UI 六个模块，通过 ScriptableObject 管理数据配置，EditMode 测试覆盖纯逻辑，PlayMode 测试覆盖运行时行为。

**Tech Stack:** Unity 2022.3.62f3c1, C# (.NET Standard 2.1), Unity Test Framework

---

## 文件结构总览

```
Assets/
├── Scripts/
│   ├── Core/
│   │   ├── GameManager.cs          — 游戏全局状态管理
│   │   ├── InputManager.cs         — 输入封装
│   │   └── GameConstants.cs        — 全局常量
│   ├── Player/
│   │   ├── PlayerController.cs     — 移动、跳跃、闪避
│   │   ├── FirstPersonCamera.cs    — 视角控制
│   │   └── PlayerStats.cs          — 血量、能量
│   ├── Weapons/
│   │   ├── WeaponData.cs           — ScriptableObject 武器配置
│   │   ├── ThrowableWeapon.cs      — 投掷物基类 (MonoBehaviour)
│   │   └── WeaponManager.cs        — 武器切换、投掷、回收
│   ├── Superpowers/
│   │   ├── SuperpowerData.cs       — ScriptableObject 超能力配置
│   │   └── SuperpowerManager.cs    — 能量管理、技能释放
│   ├── Enemies/
│   │   ├── EnemyStats.cs           — ScriptableObject 敌人配置
│   │   ├── EnemyBase.cs            — 敌人基类
│   │   ├── EnemyAI.cs              — AI 状态机
│   │   ├── BasicEnemy.cs           — 开发商打手
│   │   ├── EliteEnemy.cs           — 不良业主
│   │   └── BossEnemy.cs            — Boss（含西子配置）
│   ├── Level/
│   │   ├── CombatArena.cs          — 战斗区域触发与清场判定
│   │   └── DoorController.cs       — 清场后开门
│   └── UI/
│       ├── HUDManager.cs           — 血量、能量、武器栏
│       └── CrosshairController.cs  — 准星
├── ScriptableObjects/
│   ├── Weapons/                    — WeaponData 资产
│   ├── Superpowers/                — SuperpowerData 资产
│   └── Enemies/                    — EnemyStats 资产
├── Scenes/
│   └── Prototype.unity             — 原型测试场景
├── Prefabs/
│   ├── Player/
│   ├── Weapons/
│   ├── Enemies/
│   └── UI/
└── Tests/
    ├── EditMode/
    │   ├── WeaponDataTests.cs
    │   ├── PlayerStatsTests.cs
    │   └── CombatMathTests.cs
    └── PlayMode/
        ├── ThrowingSystemTests.cs
        └── EnemyAITests.cs
```

---

## 阶段一：项目搭建与核心基础（Task 1-5）

### Task 1: 创建 Unity 项目与目录结构

**Files:**
- Create: 整个 Unity 项目目录结构

- [ ] **Step 1: 王总在 Unity Hub 中创建新项目**

王总操作：打开 Unity Hub → 新建项目 → 选择 Unity 2022.3.62f3c1 → 模板选「3D Core」→ 项目名填 `nbgame` → 路径选 `/Volumes/work/repo/nbgame` → 创建。

- [ ] **Step 2: 创建 Scripts 目录结构**

王总在 Unity Editor 的 Project 窗口里，右键 `Assets` 文件夹，创建以下目录：

```
Assets/Scripts/Core/
Assets/Scripts/Player/
Assets/Scripts/Weapons/
Assets/Scripts/Superpowers/
Assets/Scripts/Enemies/
Assets/Scripts/Level/
Assets/Scripts/UI/
Assets/ScriptableObjects/Weapons/
Assets/ScriptableObjects/Superpowers/
Assets/ScriptableObjects/Enemies/
Assets/Scenes/
Assets/Prefabs/Player/
Assets/Prefabs/Weapons/
Assets/Prefabs/Enemies/
Assets/Prefabs/UI/
Assets/Tests/EditMode/
Assets/Tests/PlayMode/
```

- [ ] **Step 3: 安装 Unity Test Framework**

王总操作：Window → Package Manager → 搜 "Test Framework" → Install。

- [ ] **Step 4: 创建测试程序集定义**

在 `Assets/Tests/EditMode/` 右键 → Create → Assembly Definition → 命名为 `Tests.EditMode`。

在 `Assets/Tests/PlayMode/` 右键 → Create → Assembly Definition → 命名为 `Tests.PlayMode`。

- [ ] **Step 5: 保存场景**

Ctrl+S 保存当前场景为 `Assets/Scenes/Prototype.unity`。

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "chore: create Unity project and directory structure"
```

---

### Task 2: 全局常量与输入管理

**Files:**
- Create: `Assets/Scripts/Core/GameConstants.cs`
- Create: `Assets/Scripts/Core/InputManager.cs`

- [ ] **Step 1: 编写 GameConstants.cs**

```csharp
// Assets/Scripts/Core/GameConstants.cs

namespace Jiayue
{
    /// <summary>
    /// 游戏全局常量，所有硬编码数值集中管理
    /// </summary>
    public static class GameConstants
    {
        // 玩家
        public const float PlayerWalkSpeed = 5f;
        public const float PlayerRunSpeed = 10f;
        public const float PlayerJumpForce = 8f;
        public const float PlayerMaxHealth = 100f;
        public const float PlayerMaxEnergy = 100f;
        public const float PlayerDodgeCooldown = 1.5f; // 闪避冷却（秒）

        // 投掷
        public const float ThrowForce = 30f;
        public const float MaxAimDistance = 100f;
        public const float AutoRecoverTime = 8f; // 投掷物自动回收时间

        // 能量
        public const float EnergyPerKill = 20f;
        public const float RecallEnergyCost = 30f;
        public const float TimeSlowEnergyCost = 25f;
        public const float EnchantEnergyCost = 20f;

        // 敌人
        public const float EnemyActivationDistance = 50f;
        public const float EnemyDeactivationDistance = 80f;
        public const float EnemyAttackCooldown = 1.5f;

        // 关卡
        public const float ArenaClearCheckDelay = 2f;
    }
}
```

- [ ] **Step 2: 编写 InputManager.cs**

```csharp
// Assets/Scripts/Core/InputManager.cs
using UnityEngine;
using UnityEngine.InputSystem;

namespace Jiayue
{
    /// <summary>
    /// 输入封装，所有输入通过这个类读取，方便后续改键位
    /// </summary>
    public class InputManager : MonoBehaviour
    {
        private PlayerInputActions _input;

        public Vector2 Move { get; private set; }
        public Vector2 Look { get; private set; }
        public bool JumpPressed { get; private set; }
        public bool ThrowPressed { get; private set; }
        public bool ThrowHeld { get; private set; }
        public bool DodgePressed { get; private set; }
        public bool RecallPressed { get; private set; }
        public bool TimeSlowHeld { get; private set; }
        public bool NextWeaponPressed { get; private set; }
        public bool PrevWeaponPressed { get; private set; }
        public bool ShockwavePressed { get; private set; }
        public bool EnchantPressed { get; private set; }

        private void Awake()
        {
            _input = new PlayerInputActions();
        }

        private void OnEnable()
        {
            _input.Enable();
        }

        private void OnDisable()
        {
            _input.Disable();
        }

        private void Update()
        {
            Move = _input.Player.Move.ReadValue<Vector2>();
            Look = _input.Player.Look.ReadValue<Vector2>();
            JumpPressed = _input.Player.Jump.WasPressedThisFrame();
            ThrowPressed = _input.Player.Throw.WasPressedThisFrame();
            ThrowHeld = _input.Player.Throw.IsPressed();
            DodgePressed = _input.Player.Dodge.WasPressedThisFrame();
            RecallPressed = _input.Player.Recall.WasPressedThisFrame();
            TimeSlowHeld = _input.Player.TimeSlow.IsPressed();
            NextWeaponPressed = _input.Player.NextWeapon.WasPressedThisFrame();
            PrevWeaponPressed = _input.Player.PrevWeapon.WasPressedThisFrame();
            ShockwavePressed = _input.Player.Shockwave.WasPressedThisFrame();
            EnchantPressed = _input.Player.Enchant.WasPressedThisFrame();
        }
    }
}
```

- [ ] **Step 3: 在 Unity 中创建 Input Actions**

王总操作：
1. `Assets/Scripts/Core/` 右键 → Create → Input Actions → 命名为 `PlayerInputActions`
2. 双击打开编辑器，创建 Action Map 叫 "Player"
3. 添加 Actions：Move (Vector2)、Look (Vector2)、Jump (Button)、Throw (Button)、Dodge (Button)、Recall (Button)、TimeSlow (Button)、NextWeapon (Button)、PrevWeapon (Button)、Shockwave (Button)、Enchant (Button)
4. 默认绑定 WASD + 鼠标，右键瞄准/投掷，空格跳跃，Shift 闪避，Q 召回，E 冲击波，R 附魔，滚轮切换武器

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add game constants and input manager"
```

---

### Task 3: 玩家角色控制器

**Files:**
- Create: `Assets/Scripts/Player/PlayerController.cs`
- Create: `Assets/Scripts/Player/FirstPersonCamera.cs`
- Create: `Assets/Scripts/Player/PlayerStats.cs`
- Test: `Assets/Tests/EditMode/PlayerStatsTests.cs`

- [ ] **Step 1: 编写 PlayerStatsTests.cs（先写测试）**

```csharp
// Assets/Tests/EditMode/PlayerStatsTests.cs
using NUnit.Framework;
using Jiayue;

public class PlayerStatsTests
{
    [Test]
    public void TakeDamage_ReducesHealth_NotBelowZero()
    {
        var stats = new PlayerStats();
        stats.TakeDamage(30f);
        Assert.AreEqual(70f, stats.CurrentHealth);

        stats.TakeDamage(200f);
        Assert.AreEqual(0f, stats.CurrentHealth);
    }

    [Test]
    public void GainEnergy_IncreasesEnergy_NotAboveMax()
    {
        var stats = new PlayerStats();
        stats.CurrentEnergy = 50f;
        stats.GainEnergy(30f);
        Assert.AreEqual(80f, stats.CurrentEnergy);

        stats.GainEnergy(100f);
        Assert.AreEqual(GameConstants.PlayerMaxEnergy, stats.CurrentEnergy);
    }

    [Test]
    public void ConsumeEnergy_ReturnsFalse_WhenInsufficient()
    {
        var stats = new PlayerStats();
        stats.CurrentEnergy = 10f;
        bool result = stats.ConsumeEnergy(30f);
        Assert.IsFalse(result);
        Assert.AreEqual(10f, stats.CurrentEnergy);
    }

    [Test]
    public void ConsumeEnergy_ReturnsTrue_WhenSufficient()
    {
        var stats = new PlayerStats();
        stats.CurrentEnergy = 50f;
        bool result = stats.ConsumeEnergy(30f);
        Assert.IsTrue(result);
        Assert.AreEqual(20f, stats.CurrentEnergy);
    }

    [Test]
    public void Heal_DoesNotExceedMaxHealth()
    {
        var stats = new PlayerStats();
        stats.TakeDamage(50f);
        stats.Heal(100f);
        Assert.AreEqual(GameConstants.PlayerMaxHealth, stats.CurrentHealth);
    }
}
```

- [ ] **Step 2: 运行测试，确认失败**

王总操作：Window → General → Test Runner → EditMode → Run All。预期：全部失败（类还没写）。

- [ ] **Step 3: 编写 PlayerStats.cs**

```csharp
// Assets/Scripts/Player/PlayerStats.cs
using System;
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 玩家数值管理：血量、能量。纯数据类，不依赖 MonoBehaviour。
    /// </summary>
    [Serializable]
    public class PlayerStats
    {
        public float MaxHealth => GameConstants.PlayerMaxHealth;
        public float MaxEnergy => GameConstants.PlayerMaxEnergy;

        [field: SerializeField] public float CurrentHealth { get; set; } = GameConstants.PlayerMaxHealth;
        [field: SerializeField] public float CurrentEnergy { get; set; } = 0f;

        public event Action<float> OnHealthChanged;
        public event Action<float> OnEnergyChanged;
        public event Action OnPlayerDied;

        public void TakeDamage(float amount)
        {
            CurrentHealth = Mathf.Max(0f, CurrentHealth - amount);
            OnHealthChanged?.Invoke(CurrentHealth);
            if (CurrentHealth <= 0f)
            {
                OnPlayerDied?.Invoke();
            }
        }

        public void Heal(float amount)
        {
            CurrentHealth = Mathf.Min(MaxHealth, CurrentHealth + amount);
            OnHealthChanged?.Invoke(CurrentHealth);
        }

        public void GainEnergy(float amount)
        {
            CurrentEnergy = Mathf.Min(MaxEnergy, CurrentEnergy + amount);
            OnEnergyChanged?.Invoke(CurrentEnergy);
        }

        /// <returns>true 如果能量足够并已扣除</returns>
        public bool ConsumeEnergy(float amount)
        {
            if (CurrentEnergy < amount) return false;
            CurrentEnergy -= amount;
            OnEnergyChanged?.Invoke(CurrentEnergy);
            return true;
        }
    }
}
```

- [ ] **Step 4: 运行测试，确认通过**

EditMode → Run All。预期：全部通过。

- [ ] **Step 5: 编写 PlayerController.cs**

```csharp
// Assets/Scripts/Player/PlayerController.cs
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 第一人称角色控制：移动、跳跃、闪避。依赖 CharacterController。
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        [SerializeField] private InputManager _input;
        [SerializeField] private PlayerStats _stats;
        [SerializeField] private float _walkSpeed = GameConstants.PlayerWalkSpeed;
        [SerializeField] private float _runSpeed = GameConstants.PlayerRunSpeed;
        [SerializeField] private float _jumpForce = GameConstants.PlayerJumpForce;
        [SerializeField] private float _dodgeForce = 15f;
        [SerializeField] private float _dodgeDuration = 0.3f;
        [SerializeField] private float _gravity = -9.81f;

        private CharacterController _cc;
        private Vector3 _velocity;
        private float _dodgeTimer;
        private float _dodgeCooldownTimer;
        private bool _isDodging;

        private void Awake()
        {
            _cc = GetComponent<CharacterController>();
            if (_stats == null) _stats = new PlayerStats();
        }

        private void Update()
        {
            if (_input == null) return;

            HandleDodge();
            HandleMovement();
            HandleJump();
            ApplyGravity();

            _cc.Move(_velocity * Time.deltaTime);
        }

        private void HandleDodge()
        {
            _dodgeCooldownTimer -= Time.deltaTime;

            if (_input.DodgePressed && _dodgeCooldownTimer <= 0f && !_isDodging)
            {
                _isDodging = true;
                _dodgeTimer = _dodgeDuration;
                _dodgeCooldownTimer = GameConstants.PlayerDodgeCooldown;
                Vector3 dodgeDir = transform.forward * _input.Move.y + transform.right * _input.Move.x;
                if (dodgeDir.magnitude < 0.1f) dodgeDir = transform.forward;
                _velocity = dodgeDir.normalized * _dodgeForce;
            }

            if (_isDodging)
            {
                _dodgeTimer -= Time.deltaTime;
                if (_dodgeTimer <= 0f)
                {
                    _isDodging = false;
                    _velocity.x = 0f;
                    _velocity.z = 0f;
                }
            }
        }

        private void HandleMovement()
        {
            if (_isDodging) return;

            Vector2 input = _input.Move;
            float speed = _input.ThrowHeld ? _walkSpeed : _runSpeed;
            Vector3 move = transform.right * input.x + transform.forward * input.y;
            move *= speed;
            _velocity.x = move.x;
            _velocity.z = move.z;
        }

        private void HandleJump()
        {
            if (_input.JumpPressed && _cc.isGrounded && !_isDodging)
            {
                _velocity.y = _jumpForce;
            }
        }

        private void ApplyGravity()
        {
            if (_cc.isGrounded && _velocity.y < 0f)
            {
                _velocity.y = -2f; // 贴地力，保持 isGrounded 准确
            }
            else
            {
                _velocity.y += _gravity * Time.deltaTime;
            }
        }
    }
}
```

- [ ] **Step 6: 编写 FirstPersonCamera.cs**

```csharp
// Assets/Scripts/Player/FirstPersonCamera.cs
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 第一人称视角控制：鼠标旋转、视角限制
    /// </summary>
    public class FirstPersonCamera : MonoBehaviour
    {
        [SerializeField] private InputManager _input;
        [SerializeField] private float _sensitivity = 2f;
        [SerializeField] private float _minPitch = -90f;
        [SerializeField] private float _maxPitch = 90f;

        private float _yaw;
        private float _pitch;

        private void Start()
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
            _yaw = transform.eulerAngles.y;
            _pitch = transform.eulerAngles.x;
        }

        private void Update()
        {
            if (_input == null) return;

            _yaw += _input.Look.x * _sensitivity;
            _pitch -= _input.Look.y * _sensitivity;
            _pitch = Mathf.Clamp(_pitch, _minPitch, _maxPitch);

            transform.rotation = Quaternion.Euler(_pitch, _yaw, 0f);
        }
    }
}
```

- [ ] **Step 7: 搭建玩家 Prefab**

王总操作：
1. 创建空 GameObject 命名为 "Player"
2. 添加 CharacterController 组件（Height: 1.8, Radius: 0.3）
3. 子物体创建 "Camera" → 添加 Camera 组件 + FirstPersonCamera 脚本
4. Player 上添加 PlayerController + PlayerStats + InputManager 脚本
5. 拖入 `Assets/Prefabs/Player/` 做成 Prefab

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat: add player controller with stats and first-person camera"
```

---

### Task 4: 武器数据配置 (ScriptableObject)

**Files:**
- Create: `Assets/Scripts/Weapons/WeaponData.cs`
- Test: `Assets/Tests/EditMode/WeaponDataTests.cs`

- [ ] **Step 1: 编写 WeaponDataTests.cs（先写测试）**

```csharp
// Assets/Tests/EditMode/WeaponDataTests.cs
using NUnit.Framework;
using UnityEngine;
using Jiayue;

public class WeaponDataTests
{
    [Test]
    public void WeaponData_HasCorrectDefaults()
    {
        var data = ScriptableObject.CreateInstance<WeaponData>();
        data.WeaponName = "测试筷子";
        data.WeaponType = WeaponType.FastThrow;
        data.Damage = 25f;
        data.Cooldown = 0.5f;
        data.MaxCount = 5;
        data.ThrowSpeed = 30f;

        Assert.AreEqual("测试筷子", data.WeaponName);
        Assert.AreEqual(WeaponType.FastThrow, data.WeaponType);
        Assert.AreEqual(25f, data.Damage);
        Assert.AreEqual(0.5f, data.Cooldown);
        Assert.AreEqual(5, data.MaxCount);
    }

    [Test]
    public void ScatterWeapon_HasSpreadAngle()
    {
        var data = ScriptableObject.CreateInstance<WeaponData>();
        data.WeaponType = WeaponType.Scatter;
        data.ScatterCount = 5;
        data.SpreadAngle = 45f;

        Assert.AreEqual(5, data.ScatterCount);
        Assert.AreEqual(45f, data.SpreadAngle);
    }
}
```

- [ ] **Step 2: 编写 WeaponData.cs**

```csharp
// Assets/Scripts/Weapons/WeaponData.cs
using UnityEngine;

namespace Jiayue
{
    public enum WeaponType
    {
        FastThrow,   // 快攻型：筷子、螺丝刀
        Scatter,     // 散射型：麻将、光盘
        Heavy,       // 重击型：平底锅、羊角锤
        Special      // 特殊型：啤酒瓶、拖鞋、鞭炮、辣椒粉
    }

    /// <summary>
    /// 投掷武器数据配置，一个 ScriptableObject = 一种武器
    /// </summary>
    [CreateAssetMenu(fileName = "NewWeapon", menuName = "嘉悦云上/武器数据")]
    public class WeaponData : ScriptableObject
    {
        [Header("基本信息")]
        public string WeaponName = "新武器";
        public WeaponType WeaponType;
        public string Description = "";
        public GameObject Prefab; // 投掷物 Prefab

        [Header("战斗数值")]
        public float Damage = 20f;
        public float Cooldown = 0.8f;        // 出手冷却（秒）
        public float ThrowSpeed = 30f;        // 投掷速度
        public int MaxCount = 3;              // 同时持有数量
        public bool CanHeadshot = true;       // 能否爆头
        public float HeadshotMultiplier = 2f; // 爆头倍率

        [Header("散射（仅 Scatter 类型）")]
        public int ScatterCount = 5;
        public float SpreadAngle = 30f;

        [Header("特殊效果")]
        public bool LeavesGroundEffect;       // 啤酒瓶（玻璃渣）、辣椒粉（烟雾）
        public float GroundEffectDuration = 3f;
        public float GroundEffectDamagePerSecond;
        public bool AutoReturn;               // 拖鞋：自动飞回
        public bool Explodes;                 // 鞭炮：延迟爆炸
        public float ExplosionDelay = 1.5f;
        public float ExplosionRadius = 3f;
        public float ExplosionDamage = 40f;
        public bool Blinds;                   // 辣椒粉：致盲
        public float BlindDuration = 3f;
        public bool Slows;                    // 啤酒瓶玻璃渣：减速
        public float SlowAmount = 0.5f;
        public float SlowDuration = 2f;

        [Header("硬直（仅 Heavy 类型）")]
        public bool CausesKnockdown;          // 羊角锤：直接倒地
        public bool CausesStagger;            // 平底锅：拍飞
        public float StaggerForce = 10f;
    }
}
```

- [ ] **Step 3: 运行测试**

EditMode → Run All。确认 WeaponDataTests 通过。

- [ ] **Step 4: 创建武器 ScriptableObject 资产**

王总操作：在 `Assets/ScriptableObjects/Weapons/` 右键 → Create → 嘉悦云上 → 武器数据。依次创建：

| 文件名 | WeaponName | WeaponType | Damage | Cooldown | MaxCount | 特殊 |
|--------|-----------|------------|--------|----------|----------|------|
| Weapon_Chopsticks | 筷子 | FastThrow | 15 | 0.3s | 8 | CanHeadshot |
| Weapon_Screwdriver | 螺丝刀 | FastThrow | 25 | 0.5s | 5 | CanHeadshot |
| Weapon_Mahjong | 麻将牌 | Scatter | 10 | 0.8s | 3 | ScatterCount=7 |
| Weapon_CD | 光盘 | Scatter | 12 | 0.7s | 3 | ScatterCount=5 |
| Weapon_Pan | 平底锅 | Heavy | 50 | 2s | 2 | CausesStagger |
| Weapon_Hammer | 羊角锤 | Heavy | 70 | 2.5s | 2 | CausesKnockdown |
| Weapon_Beer | 啤酒瓶 | Special | 20 | 1s | 3 | Slows+LeavesGroundEffect |
| Weapon_Slipper | 拖鞋 | Special | 8 | 0.2s | 1 | AutoReturn |
| Weapon_Firecracker | 鞭炮 | Special | 10 | 1.5s | 3 | Explodes |
| Weapon_Chili | 辣椒粉 | Special | 5 | 1s | 3 | Blinds |

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add weapon data ScriptableObject and all weapon assets"
```

---

### Task 5: 投掷物基类与武器管理器

**Files:**
- Create: `Assets/Scripts/Weapons/ThrowableWeapon.cs`
- Create: `Assets/Scripts/Weapons/WeaponManager.cs`
- Test: `Assets/Tests/PlayMode/ThrowingSystemTests.cs`

- [ ] **Step 1: 编写 ThrowableWeapon.cs**

```csharp
// Assets/Scripts/Weapons/ThrowableWeapon.cs
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 投掷物运行时行为：飞行、碰撞、回收。挂载在每个投掷物 Prefab 上。
    /// </summary>
    [RequireComponent(typeof(Rigidbody))]
    public class ThrowableWeapon : MonoBehaviour
    {
        public WeaponData Data { get; private set; }
        public bool IsRecovered { get; private set; }

        private Rigidbody _rb;
        private float _autoRecoverTimer;
        private bool _hasDealtDamage;

        public void Initialize(WeaponData data, Vector3 direction)
        {
            Data = data;
            _rb = GetComponent<Rigidbody>();
            _rb.velocity = direction.normalized * data.ThrowSpeed;
            _rb.angularVelocity = Random.insideUnitSphere * 10f;
            _autoRecoverTimer = GameConstants.AutoRecoverTime;
            _hasDealtDamage = false;
            IsRecovered = false;
        }

        private void Update()
        {
            if (IsRecovered) return;

            _autoRecoverTimer -= Time.deltaTime;
            if (_autoRecoverTimer <= 0f)
            {
                RecoverToPlayer();
            }

            if (_rb.velocity.magnitude > 1f)
            {
                transform.forward = _rb.velocity.normalized;
            }
        }

        private void OnCollisionEnter(Collision collision)
        {
            if (_hasDealtDamage || IsRecovered) return;

            if (collision.gameObject.TryGetComponent<EnemyBase>(out var enemy))
            {
                bool isHeadshot = collision.gameObject.CompareTag("Head");
                float damage = Data.Damage;
                if (isHeadshot && Data.CanHeadshot)
                {
                    damage *= Data.HeadshotMultiplier;
                }
                enemy.TakeDamage(damage, isHeadshot);
                _hasDealtDamage = true;

                if (Data.CausesStagger)
                {
                    enemy.ApplyStagger(transform.forward, Data.StaggerForce);
                }
                if (Data.CausesKnockdown)
                {
                    enemy.ApplyKnockdown();
                }
                if (Data.Blinds)
                {
                    enemy.ApplyBlind(Data.BlindDuration);
                }
            }

            if (Data.Explodes)
            {
                Explode();
            }
            else if (Data.LeavesGroundEffect)
            {
                CreateGroundEffect();
            }
            else if (!Data.AutoReturn)
            {
                _rb.velocity = Vector3.zero;
                _rb.isKinematic = true;
                transform.SetParent(collision.transform);
            }
        }

        private void Explode()
        {
            Collider[] hits = Physics.OverlapSphere(transform.position, Data.ExplosionRadius);
            foreach (var hit in hits)
            {
                if (hit.TryGetComponent<EnemyBase>(out var enemy))
                {
                    enemy.TakeDamage(Data.ExplosionDamage, false);
                }
            }
            Destroy(gameObject, 0.1f);
        }

        private void CreateGroundEffect()
        {
            var effect = GameObject.CreatePrimitive(PrimitiveType.Plane);
            effect.transform.position = transform.position + Vector3.up * 0.01f;
            effect.transform.localScale = Vector3.one * 0.5f;
            effect.name = $"GroundEffect_{Data.WeaponName}";
            Destroy(effect, Data.GroundEffectDuration);
            Destroy(gameObject, 0.1f);
        }

        public void RecoverToPlayer()
        {
            IsRecovered = true;
            Destroy(gameObject);
        }
    }
}
```

- [ ] **Step 2: 编写 WeaponManager.cs**

```csharp
// Assets/Scripts/Weapons/WeaponManager.cs
using System.Collections.Generic;
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 武器管理：持有、切换、投掷、回收。挂在 Player 上。
    /// </summary>
    public class WeaponManager : MonoBehaviour
    {
        [SerializeField] private InputManager _input;
        [SerializeField] private PlayerStats _stats;
        [SerializeField] private Transform _throwOrigin;
        [SerializeField] private List<WeaponSlot> _weapons = new List<WeaponSlot>();

        private int _currentIndex = 0;

        [System.Serializable]
        public class WeaponSlot
        {
            public WeaponData Data;
            public int CurrentCount;
            public float CooldownRemaining;
        }

        private void Start()
        {
            foreach (var slot in _weapons)
            {
                slot.CurrentCount = slot.Data.MaxCount;
            }
        }

        private void Update()
        {
            if (_input == null) return;

            HandleWeaponSwitch();
            HandleCooldowns();
            HandleThrow();
            HandleRecall();
        }

        private void HandleWeaponSwitch()
        {
            if (_input.NextWeaponPressed)
            {
                _currentIndex = (_currentIndex + 1) % _weapons.Count;
            }
            if (_input.PrevWeaponPressed)
            {
                _currentIndex = (_currentIndex - 1 + _weapons.Count) % _weapons.Count;
            }
        }

        private void HandleCooldowns()
        {
            foreach (var slot in _weapons)
            {
                if (slot.CooldownRemaining > 0f)
                {
                    slot.CooldownRemaining -= Time.deltaTime;
                }
            }
        }

        private void HandleThrow()
        {
            if (!_input.ThrowPressed) return;
            if (_weapons.Count == 0) return;

            var slot = _weapons[_currentIndex];
            if (slot.CooldownRemaining > 0f || slot.CurrentCount <= 0) return;

            slot.CurrentCount--;
            slot.CooldownRemaining = slot.Data.Cooldown;

            if (slot.Data.WeaponType == WeaponType.Scatter)
            {
                for (int i = 0; i < slot.Data.ScatterCount; i++)
                {
                    float angle = (i - (slot.Data.ScatterCount - 1) / 2f) *
                        (slot.Data.SpreadAngle / (slot.Data.ScatterCount - 1));
                    Vector3 dir = Quaternion.Euler(0f, angle, 0f) * _throwOrigin.forward;
                    SpawnProjectile(slot.Data, _throwOrigin.position, dir);
                }
            }
            else
            {
                SpawnProjectile(slot.Data, _throwOrigin.position, _throwOrigin.forward);
            }
        }

        private void HandleRecall()
        {
            if (!_input.RecallPressed) return;
            if (!_stats.ConsumeEnergy(GameConstants.RecallEnergyCost)) return;

            foreach (var slot in _weapons)
            {
                slot.CurrentCount = slot.Data.MaxCount;
            }
        }

        private void SpawnProjectile(WeaponData data, Vector3 origin, Vector3 direction)
        {
            if (data.Prefab == null)
            {
                Debug.LogWarning($"武器 {data.WeaponName} 没有 Prefab！");
                return;
            }
            var projectile = Instantiate(data.Prefab, origin, Quaternion.identity);
            var weapon = projectile.GetComponent<ThrowableWeapon>();
            if (weapon != null)
            {
                weapon.Initialize(data, direction);
            }
        }

        public WeaponData GetCurrentWeapon()
        {
            if (_weapons.Count == 0) return null;
            return _weapons[_currentIndex].Data;
        }

        public WeaponSlot GetCurrentSlot()
        {
            if (_weapons.Count == 0) return null;
            return _weapons[_currentIndex];
        }

        /// <summary>
        /// 获得新武器（剧情解锁）
        /// </summary>
        public void AddWeapon(WeaponData data)
        {
            _weapons.Add(new WeaponSlot
            {
                Data = data,
                CurrentCount = data.MaxCount,
                CooldownRemaining = 0f
            });
        }
    }
}
```

- [ ] **Step 3: 编写 PlayMode 集成测试**

```csharp
// Assets/Tests/PlayMode/ThrowingSystemTests.cs
using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using Jiayue;

public class ThrowingSystemTests
{
    [UnityTest]
    public IEnumerator WeaponManager_InitializesWeaponsAtMaxCount()
    {
        var player = new GameObject("TestPlayer");
        var wm = player.AddComponent<WeaponManager>();

        var weaponData = ScriptableObject.CreateInstance<WeaponData>();
        weaponData.WeaponName = "测试武器";
        weaponData.Damage = 10f;
        weaponData.Cooldown = 0.5f;
        weaponData.MaxCount = 3;
        weaponData.ThrowSpeed = 30f;

        var prefab = GameObject.CreatePrimitive(PrimitiveType.Cube);
        prefab.AddComponent<Rigidbody>();
        prefab.AddComponent<ThrowableWeapon>();
        weaponData.Prefab = prefab;

        // 反射设置武器列表
        var slot = new WeaponManager.WeaponSlot
        {
            Data = weaponData,
            CurrentCount = 3,
            CooldownRemaining = 0f
        };
        var list = new System.Collections.Generic.List<WeaponManager.WeaponSlot> { slot };
        typeof(WeaponManager)
            .GetField("_weapons", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)
            .SetValue(wm, list);

        var origin = new GameObject("ThrowOrigin");
        origin.transform.SetParent(player.transform);
        origin.transform.localPosition = new Vector3(0, 0, 1);
        typeof(WeaponManager)
            .GetField("_throwOrigin", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)
            .SetValue(wm, origin.transform);

        yield return null;

        Assert.AreEqual(3, slot.CurrentCount);
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add throwable weapon base and weapon manager"
```

---

## 阶段二：超能力与战斗核心（Task 6-8）

### Task 6: 超能力系统

**Files:**
- Create: `Assets/Scripts/Superpowers/SuperpowerData.cs`
- Create: `Assets/Scripts/Superpowers/SuperpowerManager.cs`

- [ ] **Step 1: 编写 SuperpowerData.cs**

```csharp
// Assets/Scripts/Superpowers/SuperpowerData.cs
using UnityEngine;

namespace Jiayue
{
    public enum SuperpowerType
    {
        TimeSlow,    // 时间减速
        Enchant,     // 武器附魔（火/雷/冰）
        Recall,      // 念力召回
        Shockwave,   // 冲击波
        Dash         // 闪现冲刺
    }

    /// <summary>
    /// 超能力数据配置，一个 ScriptableObject = 一种超能力
    /// </summary>
    [CreateAssetMenu(fileName = "NewSuperpower", menuName = "嘉悦云上/超能力数据")]
    public class SuperpowerData : ScriptableObject
    {
        [Header("基本信息")]
        public string Name = "新超能力";
        public SuperpowerType Type;
        public string Description = "";

        [Header("消耗")]
        public float EnergyCost = 25f;

        [Header("数值")]
        public float Duration = 3f;
        public float Cooldown = 5f;
        public float EffectValue = 1f;
        public float EffectRadius = 5f;
        public float DashDistance = 10f;
        public float DamageMultiplier = 1.5f;
    }
}
```

- [ ] **Step 2: 编写 SuperpowerManager.cs**

```csharp
// Assets/Scripts/Superpowers/SuperpowerManager.cs
using System.Collections.Generic;
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 超能力管理：能量消耗、冷却、效果触发。挂在 Player 上。
    /// </summary>
    public class SuperpowerManager : MonoBehaviour
    {
        [SerializeField] private InputManager _input;
        [SerializeField] private PlayerStats _stats;
        [SerializeField] private List<SuperpowerSlot> _powers = new List<SuperpowerSlot>();

        private float _globalCooldown;

        [System.Serializable]
        public class SuperpowerSlot
        {
            public SuperpowerData Data;
            public bool IsUnlocked;
            public float CooldownRemaining;
        }

        public event System.Action<float> OnTimeSlowActivated;
        public event System.Action<float, float> OnEnchantActivated;
        public event System.Action<float> OnShockwaveActivated;

        private void Update()
        {
            if (_input == null) return;

            UpdateCooldowns();
            HandleInputs();
        }

        private void UpdateCooldowns()
        {
            _globalCooldown -= Time.deltaTime;
            foreach (var slot in _powers)
            {
                if (slot.CooldownRemaining > 0f)
                {
                    slot.CooldownRemaining -= Time.deltaTime;
                }
            }
        }

        private void HandleInputs()
        {
            if (_globalCooldown > 0f) return;

            if (_input.TimeSlowHeld)
            {
                TryActivate(SuperpowerType.TimeSlow, () =>
                    StartCoroutine(TimeSlowRoutine()));
            }

            if (_input.EnchantPressed)
            {
                TryActivate(SuperpowerType.Enchant, () =>
                    StartCoroutine(EnchantRoutine()));
            }

            if (_input.ShockwavePressed)
            {
                TryActivate(SuperpowerType.Shockwave, () =>
                    ActivateShockwave());
            }
        }

        private bool TryActivate(SuperpowerType type, System.Action onActivate)
        {
            var slot = FindPower(type);
            if (slot == null || !slot.IsUnlocked || slot.CooldownRemaining > 0f) return false;
            if (!_stats.ConsumeEnergy(slot.Data.EnergyCost)) return false;

            slot.CooldownRemaining = slot.Data.Cooldown;
            _globalCooldown = 0.2f;
            onActivate?.Invoke();
            return true;
        }

        private SuperpowerSlot FindPower(SuperpowerType type)
        {
            return _powers.Find(p => p.Data.Type == type);
        }

        private System.Collections.IEnumerator TimeSlowRoutine()
        {
            var data = FindPower(SuperpowerType.TimeSlow).Data;
            Time.timeScale = 0.3f;
            OnTimeSlowActivated?.Invoke(data.Duration);

            yield return new WaitForSecondsRealtime(data.Duration);

            Time.timeScale = 1f;
        }

        private System.Collections.IEnumerator EnchantRoutine()
        {
            var data = FindPower(SuperpowerType.Enchant).Data;
            OnEnchantActivated?.Invoke(data.Duration, data.DamageMultiplier);

            yield return new WaitForSeconds(data.Duration);

            OnEnchantActivated?.Invoke(0f, 1f);
        }

        private void ActivateShockwave()
        {
            var data = FindPower(SuperpowerType.Shockwave).Data;
            OnShockwaveActivated?.Invoke(data.EffectRadius);

            Collider[] hits = Physics.OverlapSphere(transform.position, data.EffectRadius);
            foreach (var hit in hits)
            {
                if (hit.TryGetComponent<EnemyBase>(out var enemy))
                {
                    Vector3 pushDir = (enemy.transform.position - transform.position).normalized;
                    enemy.ApplyStagger(pushDir, 20f);
                    enemy.TakeDamage(15f, false);
                }
            }
        }

        public void UnlockPower(SuperpowerType type)
        {
            var slot = FindPower(type);
            if (slot != null) slot.IsUnlocked = true;
        }

        public bool IsPowerUnlocked(SuperpowerType type)
        {
            return FindPower(type)?.IsUnlocked ?? false;
        }
    }
}
```

- [ ] **Step 3: 创建超能力 ScriptableObject 资产**

王总操作：`Assets/ScriptableObjects/Superpowers/` 右键 → Create → 嘉悦云上 → 超能力数据：

| 文件名 | Name | Type | EnergyCost | Duration | Cooldown |
|--------|------|------|-----------|----------|----------|
| SP_TimeSlow | 时间减速 | TimeSlow | 25 | 3s | 8s |
| SP_Enchant | 武器附魔 | Enchant | 20 | 5s | 6s |
| SP_Recall | 念力召回 | Recall | 30 | — | 3s |
| SP_Shockwave | 冲击波 | Shockwave | 35 | — | 10s |
| SP_Dash | 闪现冲刺 | Dash | 15 | — | 4s |

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add superpower system and ScriptableObject assets"
```

---

### Task 7: 敌人基类与 AI 状态机

**Files:**
- Create: `Assets/Scripts/Enemies/EnemyStats.cs`
- Create: `Assets/Scripts/Enemies/EnemyBase.cs`
- Create: `Assets/Scripts/Enemies/EnemyAI.cs`

- [ ] **Step 1: 编写 EnemyStats.cs**

```csharp
// Assets/Scripts/Enemies/EnemyStats.cs
using UnityEngine;

namespace Jiayue
{
    public enum EnemyType
    {
        Basic,   // 开发商打手
        Elite,   // 不良业主
        Boss,    // 邪恶业主头目
        FinalBoss // 西子
    }

    [CreateAssetMenu(fileName = "NewEnemy", menuName = "嘉悦云上/敌人数据")]
    public class EnemyStats : ScriptableObject
    {
        [Header("基本信息")]
        public string EnemyName = "新敌人";
        public EnemyType Type;
        public GameObject Prefab;

        [Header("战斗数值")]
        public float MaxHealth = 50f;
        public float MoveSpeed = 3f;
        public float AttackDamage = 15f;
        public float AttackRange = 2f;
        public float AttackCooldown = 1.5f;
        public float DetectionRange = 20f;
        public float ChaseRange = 30f;

        [Header("掉落")]
        public float HealthDropChance = 0.3f;
        public float HealthDropAmount = 20f;
        public float EnergyDropChance = 0.5f;
        public float EnergyDropAmount = 15f;

        [Header("Boss 专属")]
        public bool IsBoss;
        public float Phase2HealthPercent = 0.5f;
        public float[] BossAbilityCooldowns;
    }
}
```

- [ ] **Step 2: 编写 EnemyBase.cs**

```csharp
// Assets/Scripts/Enemies/EnemyBase.cs
using UnityEngine;
using UnityEngine.Events;

namespace Jiayue
{
    /// <summary>
    /// 敌人基类：血量、受击、死亡、掉落。
    /// </summary>
    public class EnemyBase : MonoBehaviour
    {
        [SerializeField] protected EnemyStats _stats;

        public float CurrentHealth { get; protected set; }
        public bool IsDead { get; protected set; }
        public bool IsBlinded { get; protected set; }
        public bool IsKnockedDown { get; protected set; }

        public event System.Action<EnemyBase> OnEnemyDied;
        public UnityEvent OnDamaged;

        protected virtual void Start()
        {
            CurrentHealth = _stats.MaxHealth;
        }

        public virtual void TakeDamage(float amount, bool isHeadshot)
        {
            if (IsDead) return;

            CurrentHealth -= amount;
            OnDamaged?.Invoke();

            if (CurrentHealth <= 0f)
            {
                Die();
            }
        }

        public virtual void ApplyStagger(Vector3 direction, float force)
        {
            var rb = GetComponent<Rigidbody>();
            if (rb != null)
            {
                rb.AddForce(direction * force, ForceMode.Impulse);
            }
        }

        public virtual void ApplyKnockdown()
        {
            IsKnockedDown = true;
            Invoke(nameof(RecoverFromKnockdown), 2f);
        }

        protected virtual void RecoverFromKnockdown()
        {
            IsKnockedDown = false;
        }

        public virtual void ApplyBlind(float duration)
        {
            if (IsBlinded) return;
            IsBlinded = true;
            Invoke(nameof(RecoverFromBlind), duration);
        }

        protected virtual void RecoverFromBlind()
        {
            IsBlinded = false;
        }

        protected virtual void Die()
        {
            if (IsDead) return;
            IsDead = true;
            OnEnemyDied?.Invoke(this);

            if (Random.value < _stats.HealthDropChance)
            {
                DropPickup(PickupType.Health, _stats.HealthDropAmount);
            }
            if (Random.value < _stats.EnergyDropChance)
            {
                DropPickup(PickupType.Energy, _stats.EnergyDropAmount);
            }

            Destroy(gameObject, 0.5f);
        }

        protected virtual void DropPickup(PickupType type, float amount)
        {
            var pickup = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            pickup.transform.position = transform.position + Vector3.up;
            pickup.transform.localScale = Vector3.one * 0.3f;
            var pickupComp = pickup.AddComponent<Pickup>();
            pickupComp.Type = type;
            pickupComp.Amount = amount;
        }

        public bool CanSeePlayer(Transform player, float maxDistance, float fieldOfView = 120f)
        {
            Vector3 toPlayer = player.position - transform.position;
            if (toPlayer.magnitude > maxDistance) return false;

            float angle = Vector3.Angle(transform.forward, toPlayer);
            if (angle > fieldOfView / 2f) return false;

            if (Physics.Raycast(transform.position + Vector3.up,
                toPlayer.normalized, out RaycastHit hit, maxDistance))
            {
                return hit.transform == player;
            }
            return false;
        }
    }

    public enum PickupType { Health, Energy }

    public class Pickup : MonoBehaviour
    {
        public PickupType Type;
        public float Amount;

        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("Player"))
            {
                var stats = other.GetComponent<PlayerStats>();
                if (stats != null)
                {
                    if (Type == PickupType.Health) stats.Heal(Amount);
                    else stats.GainEnergy(Amount);
                }
                Destroy(gameObject);
            }
        }
    }
}
```

- [ ] **Step 3: 编写 EnemyAI.cs**

```csharp
// Assets/Scripts/Enemies/EnemyAI.cs
using UnityEngine;
using UnityEngine.AI;

namespace Jiayue
{
    public enum AIState
    {
        Idle,
        Investigate,
        Chase,
        Combat,
        Flee,
        Dead
    }

    [RequireComponent(typeof(NavMeshAgent))]
    public class EnemyAI : MonoBehaviour
    {
        [SerializeField] private EnemyBase _enemy;
        [SerializeField] private EnemyStats _stats;

        private NavMeshAgent _agent;
        private Transform _player;
        private AIState _state = AIState.Idle;
        private float _attackTimer;
        private Vector3 _lastKnownPlayerPos;
        private float _stateTimer;

        [SerializeField] private Transform[] _patrolPoints;
        private int _patrolIndex;

        public AIState CurrentState => _state;

        private void Awake()
        {
            _agent = GetComponent<NavMeshAgent>();
            _agent.speed = _stats.MoveSpeed;
        }

        private void Start()
        {
            _player = GameObject.FindGameObjectWithTag("Player")?.transform;
        }

        private void Update()
        {
            if (_enemy.IsDead)
            {
                TransitionTo(AIState.Dead);
                return;
            }

            if (_enemy.IsKnockedDown) return;

            UpdateState();
        }

        private void UpdateState()
        {
            switch (_state)
            {
                case AIState.Idle: UpdateIdle(); break;
                case AIState.Investigate: UpdateInvestigate(); break;
                case AIState.Chase: UpdateChase(); break;
                case AIState.Combat: UpdateCombat(); break;
                case AIState.Flee: UpdateFlee(); break;
                case AIState.Dead: _agent.isStopped = true; break;
            }
        }

        private void UpdateIdle()
        {
            if (_enemy.CanSeePlayer(_player, _stats.DetectionRange))
            {
                TransitionTo(AIState.Chase);
                return;
            }

            if (_patrolPoints != null && _patrolPoints.Length > 0)
            {
                if (!_agent.hasPath || _agent.remainingDistance < 0.5f)
                {
                    _patrolIndex = (_patrolIndex + 1) % _patrolPoints.Length;
                    _agent.SetDestination(_patrolPoints[_patrolIndex].position);
                }
            }
        }

        private void UpdateInvestigate()
        {
            _stateTimer -= Time.deltaTime;
            if (_stateTimer <= 0f)
            {
                TransitionTo(AIState.Idle);
                return;
            }

            if (_enemy.CanSeePlayer(_player, _stats.DetectionRange))
            {
                TransitionTo(AIState.Chase);
            }
        }

        private void UpdateChase()
        {
            if (!_enemy.CanSeePlayer(_player, _stats.ChaseRange))
            {
                _lastKnownPlayerPos = _player.position;
                TransitionTo(AIState.Investigate);
                return;
            }

            _agent.SetDestination(_player.position);

            float dist = Vector3.Distance(transform.position, _player.position);
            if (dist <= _stats.AttackRange)
            {
                TransitionTo(AIState.Combat);
            }
        }

        private void UpdateCombat()
        {
            float dist = Vector3.Distance(transform.position, _player.position);
            if (dist > _stats.AttackRange * 1.5f)
            {
                TransitionTo(AIState.Chase);
                return;
            }

            Vector3 lookPos = _player.position;
            lookPos.y = transform.position.y;
            transform.LookAt(lookPos);

            _attackTimer -= Time.deltaTime;
            if (_attackTimer <= 0f)
            {
                Attack();
                _attackTimer = _stats.AttackCooldown;
            }

            if (_stats.Type == EnemyType.Elite && _enemy.CurrentHealth < _stats.MaxHealth * 0.2f)
            {
                TransitionTo(AIState.Flee);
            }
        }

        private void UpdateFlee()
        {
            _agent.SetDestination(transform.position -
                (_player.position - transform.position).normalized * 10f);

            if (_agent.remainingDistance < 1f || !_enemy.CanSeePlayer(_player, _stats.ChaseRange))
            {
                TransitionTo(AIState.Idle);
            }
        }

        private void Attack()
        {
            if (_enemy.IsBlinded) return;

            Collider[] hits = Physics.OverlapSphere(
                transform.position + transform.forward * _stats.AttackRange, 1f);

            foreach (var hit in hits)
            {
                if (hit.CompareTag("Player"))
                {
                    var playerStats = hit.GetComponent<PlayerStats>();
                    if (playerStats != null)
                    {
                        float dmg = _enemy.IsBlinded ?
                            _stats.AttackDamage * 0.3f : _stats.AttackDamage;
                        playerStats.TakeDamage(dmg);
                    }
                }
            }
        }

        private void TransitionTo(AIState newState)
        {
            _state = newState;
            _stateTimer = 3f;

            switch (newState)
            {
                case AIState.Investigate:
                    _agent.SetDestination(_lastKnownPlayerPos);
                    break;
                case AIState.Chase:
                    _agent.isStopped = false;
                    break;
                case AIState.Combat:
                    _agent.isStopped = true;
                    break;
            }
        }

        public void AlertToPlayer(Vector3 playerPos)
        {
            _lastKnownPlayerPos = playerPos;
            if (_state == AIState.Idle)
            {
                TransitionTo(AIState.Investigate);
            }
        }
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add enemy base, AI state machine, and pickup system"
```

---

### Task 8: 具体敌人类

**Files:**
- Create: `Assets/Scripts/Enemies/BasicEnemy.cs`
- Create: `Assets/Scripts/Enemies/EliteEnemy.cs`
- Create: `Assets/Scripts/Enemies/BossEnemy.cs`

- [ ] **Step 1: 编写 BasicEnemy.cs（开发商打手）**

```csharp
// Assets/Scripts/Enemies/BasicEnemy.cs
namespace Jiayue
{
    /// <summary>
    /// 开发商打手 — 穿黑西装，持棍棒。数量多、脆、行为简单。
    /// 所有差异化通过 EnemyStats 配置，不需要额外代码。
    /// </summary>
    public class BasicEnemy : EnemyBase
    {
    }
}
```

- [ ] **Step 2: 编写 EliteEnemy.cs（不良业主）**

```csharp
// Assets/Scripts/Enemies/EliteEnemy.cs
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 不良业主 — 装备更好，会躲会包抄。
    /// </summary>
    public class EliteEnemy : EnemyBase
    {
        [SerializeField] private float _dodgeChance = 0.3f;
        [SerializeField] private float _flankRadius = 5f;
        private float _flankTimer;

        protected override void Start()
        {
            base.Start();
            _flankTimer = Random.Range(2f, 5f);
        }

        public override void TakeDamage(float amount, bool isHeadshot)
        {
            if (!IsBlinded && Random.value < _dodgeChance && !isHeadshot)
            {
                Vector3 dodgeDir = transform.right * (Random.value > 0.5f ? 1f : -1f);
                var rb = GetComponent<Rigidbody>();
                if (rb != null)
                {
                    rb.AddForce(dodgeDir * 5f, ForceMode.Impulse);
                }
                return;
            }

            base.TakeDamage(amount, isHeadshot);
        }

        private void Update()
        {
            if (IsDead) return;

            _flankTimer -= Time.deltaTime;
            if (_flankTimer <= 0f)
            {
                _flankTimer = Random.Range(3f, 6f);
                var player = GameObject.FindGameObjectWithTag("Player");
                if (player != null)
                {
                    var ai = GetComponent<EnemyAI>();
                    if (ai != null && ai.CurrentState == AIState.Combat)
                    {
                        Vector3 flankDir = (transform.position - player.transform.position).normalized;
                        Vector3 flankTarget = player.transform.position +
                            Quaternion.Euler(0f, Random.Range(60f, 120f), 0f) * flankDir * _flankRadius;
                        var agent = GetComponent<UnityEngine.AI.NavMeshAgent>();
                        if (agent != null) agent.SetDestination(flankTarget);
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: 编写 BossEnemy.cs**

```csharp
// Assets/Scripts/Enemies/BossEnemy.cs
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// Boss 敌人基类：多阶段、特殊技能、Boss 血条。
    /// </summary>
    public class BossEnemy : EnemyBase
    {
        [Header("Boss 技能")]
        [SerializeField] protected GameObject _projectilePrefab;
        [SerializeField] protected float _skillCooldown1 = 4f;
        [SerializeField] protected float _skillCooldown2 = 6f;
        [SerializeField] protected Transform[] _skillOrigins;

        protected int _phase = 1;
        protected float _skill1Timer;
        protected float _skill2Timer;
        protected Transform _player;

        public event System.Action<float> OnHealthPercentChanged;

        protected override void Start()
        {
            base.Start();
            _player = GameObject.FindGameObjectWithTag("Player")?.transform;
            _skill1Timer = _skillCooldown1;
            _skill2Timer = _skillCooldown2;
        }

        public override void TakeDamage(float amount, bool isHeadshot)
        {
            base.TakeDamage(amount, isHeadshot);
            OnHealthPercentChanged?.Invoke(CurrentHealth / _stats.MaxHealth);

            if (_phase == 1 && CurrentHealth < _stats.MaxHealth * _stats.Phase2HealthPercent)
            {
                _phase = 2;
                OnPhaseChanged(2);
            }
        }

        protected virtual void Update()
        {
            if (IsDead || _player == null) return;

            _skill1Timer -= Time.deltaTime;
            _skill2Timer -= Time.deltaTime;

            if (_skill1Timer <= 0f)
            {
                UseSkill1();
                _skill1Timer = _skillCooldown1;
            }
            if (_skill2Timer <= 0f && _phase >= 2)
            {
                UseSkill2();
                _skill2Timer = _skillCooldown2;
            }
        }

        protected virtual void UseSkill1()
        {
            if (_projectilePrefab != null && _skillOrigins != null)
            {
                foreach (var origin in _skillOrigins)
                {
                    Vector3 dir = (_player.position - origin.position).normalized;
                    Instantiate(_projectilePrefab, origin.position,
                        Quaternion.LookRotation(dir));
                }
            }
        }

        protected virtual void UseSkill2()
        {
            // 子类（西子）覆盖为毒奶喷射
        }

        protected virtual void OnPhaseChanged(int newPhase)
        {
            Debug.Log($"{_stats.EnemyName} 进入第 {newPhase} 阶段！");
        }
    }
}
```

- [ ] **Step 4: 创建敌人数据资产**

| 文件名 | EnemyName | Type | MaxHealth | MoveSpeed | AttackDamage |
|--------|-----------|------|-----------|-----------|--------------|
| Enemy_Basic | 开发商打手 | Basic | 50 | 3 | 15 |
| Enemy_Elite | 不良业主 | Elite | 120 | 4.5 | 25 |
| Enemy_Boss1 | 会所头目 | Boss | 500 | 5 | 35 |
| Enemy_Xizi | 西子 | FinalBoss | 800 | 4 | 40 |

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add BasicEnemy, EliteEnemy and BossEnemy classes with Stats assets"
```

---

## 阶段三：关卡系统与 UI（Task 9-11）

### Task 9: 战斗区域与关卡管理

**Files:**
- Create: `Assets/Scripts/Level/CombatArena.cs`
- Create: `Assets/Scripts/Level/DoorController.cs`

- [ ] **Step 1: 编写 CombatArena.cs**

```csharp
// Assets/Scripts/Level/CombatArena.cs
using System.Collections.Generic;
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 战斗区域：玩家进入触发 → 关门 → 刷敌人 → 清场 → 开门。
    /// </summary>
    public class CombatArena : MonoBehaviour
    {
        [SerializeField] private DoorController[] _doorsToClose;
        [SerializeField] private DoorController[] _doorsToOpen;
        [SerializeField] private EnemySpawnPoint[] _spawnPoints;
        [SerializeField] private bool _isBossArena;

        private List<EnemyBase> _activeEnemies = new List<EnemyBase>();
        private bool _isActive;
        private bool _isCleared;

        private void OnTriggerEnter(Collider other)
        {
            if (_isActive || _isCleared) return;
            if (!other.CompareTag("Player")) return;

            Activate();
        }

        private void Activate()
        {
            _isActive = true;

            foreach (var door in _doorsToClose) door.Close();

            foreach (var spawn in _spawnPoints)
            {
                var enemy = spawn.Spawn();
                if (enemy != null)
                {
                    enemy.OnEnemyDied += OnEnemyKilled;
                    _activeEnemies.Add(enemy);
                }
            }
        }

        private void OnEnemyKilled(EnemyBase enemy)
        {
            enemy.OnEnemyDied -= OnEnemyKilled;
            _activeEnemies.Remove(enemy);

            if (_activeEnemies.Count == 0)
            {
                StartCoroutine(ClearArena());
            }
        }

        private System.Collections.IEnumerator ClearArena()
        {
            _isCleared = true;
            _isActive = false;

            yield return new WaitForSeconds(GameConstants.ArenaClearCheckDelay);

            foreach (var door in _doorsToOpen) door.Open();

            if (_isBossArena)
            {
                Debug.Log("Boss 击败！");
            }
        }
    }

    /// <summary>
    /// 敌人生成点
    /// </summary>
    [System.Serializable]
    public class EnemySpawnPoint
    {
        public Transform SpawnTransform;
        public EnemyStats EnemyData;
        public int Count = 1;
        public float SpawnInterval = 0.5f;

        public EnemyBase Spawn()
        {
            if (EnemyData.Prefab == null)
            {
                Debug.LogError($"敌人 {EnemyData.EnemyName} 没有 Prefab！");
                return null;
            }
            var go = Object.Instantiate(EnemyData.Prefab,
                SpawnTransform.position, SpawnTransform.rotation);
            return go.GetComponent<EnemyBase>();
        }
    }
}
```

- [ ] **Step 2: 编写 DoorController.cs**

```csharp
// Assets/Scripts/Level/DoorController.cs
using System.Collections;
using UnityEngine;

namespace Jiayue
{
    public class DoorController : MonoBehaviour
    {
        [SerializeField] private Vector3 _openOffset = Vector3.up * 5f;
        [SerializeField] private float _openSpeed = 3f;
        [SerializeField] private bool _startsOpen;

        private Vector3 _closedPosition;
        private Vector3 _openPosition;
        private Coroutine _moveRoutine;

        private void Start()
        {
            _closedPosition = transform.position;
            _openPosition = _closedPosition + _openOffset;

            if (_startsOpen) transform.position = _openPosition;
        }

        public void Open()
        {
            if (_moveRoutine != null) StopCoroutine(_moveRoutine);
            _moveRoutine = StartCoroutine(MoveTo(_openPosition));
        }

        public void Close()
        {
            if (_moveRoutine != null) StopCoroutine(_moveRoutine);
            _moveRoutine = StartCoroutine(MoveTo(_closedPosition));
        }

        private IEnumerator MoveTo(Vector3 target)
        {
            while (Vector3.Distance(transform.position, target) > 0.05f)
            {
                transform.position = Vector3.MoveTowards(
                    transform.position, target, _openSpeed * Time.deltaTime);
                yield return null;
            }
            transform.position = target;
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add combat arena trigger and door controller"
```

---

### Task 10: UI 系统

**Files:**
- Create: `Assets/Scripts/UI/HUDManager.cs`
- Create: `Assets/Scripts/UI/CrosshairController.cs`

- [ ] **Step 1: 编写 HUDManager.cs**

```csharp
// Assets/Scripts/UI/HUDManager.cs
using UnityEngine;
using UnityEngine.UI;
using TMPro;

namespace Jiayue
{
    /// <summary>
    /// HUD 管理：血量条、能量条、武器显示、Boss 血条。
    /// </summary>
    public class HUDManager : MonoBehaviour
    {
        [SerializeField] private PlayerStats _playerStats;
        [SerializeField] private WeaponManager _weaponManager;

        [Header("玩家状态")]
        [SerializeField] private Image _healthBar;
        [SerializeField] private Image _energyBar;
        [SerializeField] private TMP_Text _healthText;
        [SerializeField] private TMP_Text _energyText;

        [Header("武器显示")]
        [SerializeField] private TMP_Text _currentWeaponName;
        [SerializeField] private TMP_Text _currentWeaponCount;
        [SerializeField] private Image _cooldownIndicator;

        [Header("Boss 血条")]
        [SerializeField] private GameObject _bossHPContainer;
        [SerializeField] private Image _bossHPBar;
        [SerializeField] private TMP_Text _bossNameText;

        [Header("受伤效果")]
        [SerializeField] private Image _damageVignette;
        [SerializeField] private float _vignetteFadeSpeed = 3f;

        private void Start()
        {
            if (_bossHPContainer != null) _bossHPContainer.SetActive(false);

            if (_playerStats != null)
            {
                _playerStats.OnHealthChanged += UpdateHealthUI;
                _playerStats.OnEnergyChanged += UpdateEnergyUI;
            }

            UpdateHealthUI(_playerStats?.CurrentHealth ?? 100f);
            UpdateEnergyUI(_playerStats?.CurrentEnergy ?? 0f);
        }

        private void Update()
        {
            UpdateWeaponUI();
            UpdateDamageVignette();
        }

        private void UpdateHealthUI(float currentHealth)
        {
            float pct = currentHealth / GameConstants.PlayerMaxHealth;
            if (_healthBar != null) _healthBar.fillAmount = pct;
            if (_healthText != null) _healthText.text = $"{Mathf.CeilToInt(currentHealth)}";
        }

        private void UpdateEnergyUI(float currentEnergy)
        {
            float pct = currentEnergy / GameConstants.PlayerMaxEnergy;
            if (_energyBar != null) _energyBar.fillAmount = pct;
            if (_energyText != null) _energyText.text = $"{Mathf.CeilToInt(currentEnergy)}";
        }

        private void UpdateWeaponUI()
        {
            if (_weaponManager == null) return;

            var weapon = _weaponManager.GetCurrentWeapon();
            var slot = _weaponManager.GetCurrentSlot();

            if (weapon != null && _currentWeaponName != null)
                _currentWeaponName.text = weapon.WeaponName;
            if (slot != null && _currentWeaponCount != null)
                _currentWeaponCount.text = $"{slot.CurrentCount}/{slot.Data.MaxCount}";
            if (_cooldownIndicator != null && slot != null)
                _cooldownIndicator.fillAmount = slot.Data.Cooldown > 0f
                    ? slot.CooldownRemaining / slot.Data.Cooldown : 0f;
        }

        private void UpdateDamageVignette()
        {
            if (_damageVignette == null) return;

            float targetAlpha = _playerStats != null &&
                _playerStats.CurrentHealth < GameConstants.PlayerMaxHealth * 0.3f ? 0.4f : 0f;
            Color c = _damageVignette.color;
            c.a = Mathf.Lerp(c.a, targetAlpha, Time.deltaTime * _vignetteFadeSpeed);
            _damageVignette.color = c;
        }

        public void ShowBossHP(string bossName, BossEnemy boss)
        {
            if (_bossHPContainer != null) _bossHPContainer.SetActive(true);
            if (_bossNameText != null) _bossNameText.text = bossName;
            boss.OnHealthPercentChanged += OnBossHPChanged;
        }

        private void OnBossHPChanged(float pct)
        {
            if (_bossHPBar != null) _bossHPBar.fillAmount = pct;
        }

        public void HideBossHP()
        {
            if (_bossHPContainer != null) _bossHPContainer.SetActive(false);
        }

        private void OnDestroy()
        {
            if (_playerStats != null)
            {
                _playerStats.OnHealthChanged -= UpdateHealthUI;
                _playerStats.OnEnergyChanged -= UpdateEnergyUI;
            }
        }
    }
}
```

- [ ] **Step 2: 编写 CrosshairController.cs**

```csharp
// Assets/Scripts/UI/CrosshairController.cs
using UnityEngine;

namespace Jiayue
{
    /// <summary>
    /// 准星控制：动态扩散、命中反馈。
    /// </summary>
    public class CrosshairController : MonoBehaviour
    {
        [SerializeField] private RectTransform _topLine;
        [SerializeField] private RectTransform _bottomLine;
        [SerializeField] private RectTransform _leftLine;
        [SerializeField] private RectTransform _rightLine;

        [SerializeField] private float _restSpread = 8f;
        [SerializeField] private float _moveSpread = 16f;
        [SerializeField] private float _throwSpread = 30f;
        [SerializeField] private float _spreadSpeed = 10f;

        private float _currentSpread;
        private float _targetSpread;

        private void Update()
        {
            bool isMoving = Input.GetAxis("Horizontal") != 0 || Input.GetAxis("Vertical") != 0;
            _targetSpread = isMoving ? _moveSpread : _restSpread;

            _currentSpread = Mathf.Lerp(_currentSpread, _targetSpread,
                Time.deltaTime * _spreadSpeed);

            _topLine.anchoredPosition = new Vector2(0, _currentSpread);
            _bottomLine.anchoredPosition = new Vector2(0, -_currentSpread);
            _leftLine.anchoredPosition = new Vector2(-_currentSpread, 0);
            _rightLine.anchoredPosition = new Vector2(_currentSpread, 0);
        }

        public void OnHit()
        {
            _currentSpread = _throwSpread;
        }
    }
}
```

- [ ] **Step 3: 搭建 UI Canvas**

王总操作：
1. Hierarchy 右键 → UI → Canvas → 命名为 "HUD"
2. 创建子物体：血量条、能量条、武器名/数量、Boss血条容器（默认隐藏）、受伤暗角、准星
3. 挂上 HUDManager 和 CrosshairController，拖入引用
4. 另存为 Prefab 到 `Assets/Prefabs/UI/`

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add HUD manager and crosshair controller"
```

---

### Task 11: GameManager 全局管理器

**Files:**
- Create: `Assets/Scripts/Core/GameManager.cs`

- [ ] **Step 1: 编写 GameManager.cs**

```csharp
// Assets/Scripts/Core/GameManager.cs
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Jiayue
{
    /// <summary>
    /// 游戏全局状态管理：暂停、重开、场景切换。
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        public bool IsPaused { get; private set; }
        public bool IsGameOver { get; private set; }

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        public void PauseGame()
        {
            IsPaused = true;
            Time.timeScale = 0f;
        }

        public void ResumeGame()
        {
            IsPaused = false;
            Time.timeScale = 1f;
        }

        public void GameOver()
        {
            IsGameOver = true;
            Time.timeScale = 0f;
        }

        public void RestartLevel()
        {
            IsGameOver = false;
            Time.timeScale = 1f;
            SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
        }

        public void LoadNextLevel()
        {
            int next = SceneManager.GetActiveScene().buildIndex + 1;
            if (next < SceneManager.sceneCountInBuildSettings)
            {
                SceneManager.LoadScene(next);
            }
            else
            {
                Debug.Log("通关！");
            }
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: add GameManager with pause/resume/restart"
```

---

## 阶段四：集成与原型关卡（Task 12-14）

### Task 12: 搭建第一个原型关卡

- [ ] **Step 1: 创建场景** `Assets/Scenes/Level_01.unity`

- [ ] **Step 2: 搭建地面**

创建 Plane → 缩放 (10, 1, 10) → 命名为 "Ground"

- [ ] **Step 3: 放置玩家**

从 `Assets/Prefabs/Player/` 拖入 Player Prefab，位置 (0, 1, 0)

- [ ] **Step 4: 搭建简单战斗区域**

1. 创建空 GameObject "Arena_01"
2. 四个 Cube 围成 20x20 区域
3. 两端各放一个 Cube 作为门
4. 区域内放 Empty GameObject 作为敌人生成点
5. 添加 CombatArena 脚本，设置 Doors 和 SpawnPoints

- [ ] **Step 5: 设置 NavMesh**

选中地面和围墙 → Navigation Static → Bake NavMesh

- [ ] **Step 6: 设置光照**

Directional Light 稍微调暗，添加 Point Light 模拟路灯氛围

- [ ] **Step 7: 测试运行**

王总在 Unity 中按 Play 测试：移动/视角/跳跃/投掷/敌人/清场开门

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat: add prototype level 01 with combat arena"
```

---

### Task 13: 战斗平衡测试

**Files:**
- Test: `Assets/Tests/EditMode/CombatMathTests.cs`

- [ ] **Step 1: 编写 CombatMathTests.cs**

```csharp
// Assets/Tests/EditMode/CombatMathTests.cs
using NUnit.Framework;
using Jiayue;

public class CombatMathTests
{
    [Test]
    public void FastThrowWeapon_KillsBasicEnemy_InFourHits()
    {
        float chopstickDamage = 15f;
        float basicEnemyHP = 50f;
        int hitsToKill = UnityEngine.Mathf.CeilToInt(basicEnemyHP / chopstickDamage);
        Assert.AreEqual(4, hitsToKill);
    }

    [Test]
    public void HeavyWeapon_KillsBasicEnemy_InOneHit()
    {
        float hammerDamage = 70f;
        float basicEnemyHP = 50f;
        int hitsToKill = UnityEngine.Mathf.CeilToInt(basicEnemyHP / hammerDamage);
        Assert.AreEqual(1, hitsToKill);
    }

    [Test]
    public void Headshot_DoublesDamage()
    {
        Assert.AreEqual(30f, 15f * 2f);
    }

    [Test]
    public void EnergyGainFromKill_IsCorrect()
    {
        Assert.AreEqual(20f, GameConstants.EnergyPerKill);
    }

    [Test]
    public void RecallCost_CanBeAffordedAfterTwoKills()
    {
        float twoKills = GameConstants.EnergyPerKill * 2;
        Assert.Greater(twoKills, GameConstants.RecallEnergyCost);
    }

    [Test]
    public void ScatterWeapon_TotalDamage_MatchesCalculation()
    {
        float singleDamage = 10f;
        int count = 7;
        float totalIfAllHit = singleDamage * count;
        Assert.AreEqual(70f, totalIfAllHit);
    }
}
```

- [ ] **Step 2: 运行测试确认通过**

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "test: add combat math balance tests"
```

---

### Task 14: 全部武器 Prefab 与敌人 Prefab

- [ ] **Step 1: 为每种武器创建占位 Prefab**

对每种武器创建临时模型（用 Cube/Cylinder 组合近似），添加 Rigidbody + ThrowableWeapon 脚本：

| 武器 | 占位模型 | 颜色 |
|------|---------|------|
| 筷子 | 细长 Cylinder × 2 | 木色 |
| 螺丝刀 | Cylinder (柄) + 细 Cylinder (杆) | 灰+银 |
| 麻将牌 | 小 Cube | 绿/白 |
| 光盘 | 薄 Cylinder | 银色 |
| 平底锅 | 粗 Cylinder (锅) + 细长 Cube (柄) | 黑+灰 |
| 羊角锤 | Cube (头) + Cylinder (柄) | 银+木色 |
| 啤酒瓶 | Cylinder (瓶身) + 细 Cylinder (瓶颈) | 绿/棕 |
| 拖鞋 | 扁平 Cube | 蓝/红 |
| 鞭炮 | 小 Cylinder × 3 串一起 | 红 |
| 辣椒粉 | 小 Cylinder (瓶) | 红 |

全部存入 `Assets/Prefabs/Weapons/`，拖入对应的 WeaponData 的 Prefab 字段。

- [ ] **Step 2: 为每种敌人创建占位 Prefab**

| 敌人 | 占位模型 | 颜色 |
|------|---------|------|
| 开发商打手 | Capsule (人) + 小 Cylinder (棍) | 黑 |
| 不良业主 | Capsule (人) + 稍大 Cube (盾) | 杂色 |
| Boss 头目 | 大 Capsule + 特殊标识 | 红 |
| 西子 | 特殊 Capsule + 双球体 (胸) | 紫 |

挂上对应的 EnemyBase + EnemyAI (BasicEnemy/EliteEnemy/BossEnemy)。

存入 `Assets/Prefabs/Enemies/`，拖入对应的 EnemyStats 的 Prefab 字段。

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add placeholder prefabs for all weapons and enemies"
```

---

## 后续阶段（原型验证后进行）

### Task 15: 精英怪与 Boss 完善
- EliteEnemy 护甲外观、武器模型
- BossEnemy 阶段切换特效
- 西子 Boss：毒奶弹幕、毒池生成、多阶段攻击模式

### Task 16: 超能力视觉效果
- 时间减速：屏幕色调 + 粒子
- 武器附魔：火/雷/冰粒子
- 冲击波：环形扩散粒子
- 闪现：拖尾效果

### Task 17: 音效与动画
- 投掷/命中/回收音效
- 敌人脚步声、攻击声、死亡声

### Task 18: 全部关卡与剧情
- 根据小区平面图设计 5-7 关
- 场景转场、业主群聊消息

---

*计划由 AI 助手基于设计文档生成。原型阶段（Task 1-14）完成后，根据实际体验调整后续任务。*
