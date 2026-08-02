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
