using System;
using UnityEngine;

namespace Jiayue
{
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
            if (CurrentHealth <= 0f) OnPlayerDied?.Invoke();
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

        public bool ConsumeEnergy(float amount)
        {
            if (CurrentEnergy < amount) return false;
            CurrentEnergy -= amount;
            OnEnergyChanged?.Invoke(CurrentEnergy);
            return true;
        }
    }
}
