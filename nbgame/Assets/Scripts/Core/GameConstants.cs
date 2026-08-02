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
        public const float PlayerDodgeCooldown = 1.5f;

        // 投掷
        public const float ThrowForce = 30f;
        public const float MaxAimDistance = 100f;
        public const float AutoRecoverTime = 8f;

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
