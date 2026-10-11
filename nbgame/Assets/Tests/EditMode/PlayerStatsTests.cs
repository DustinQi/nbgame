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
}
