using UnityEngine;

namespace Jiayue
{
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
                Vector3 dir = transform.forward * _input.Move.y + transform.right * _input.Move.x;
                if (dir.magnitude < 0.1f) dir = transform.forward;
                _velocity = dir.normalized * _dodgeForce;
            }
            if (_isDodging)
            {
                _dodgeTimer -= Time.deltaTime;
                if (_dodgeTimer <= 0f) { _isDodging = false; _velocity.x = 0f; _velocity.z = 0f; }
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
                _velocity.y = _jumpForce;
        }

        private void ApplyGravity()
        {
            if (_cc.isGrounded && _velocity.y < 0f)
                _velocity.y = -2f;
            else
                _velocity.y += _gravity * Time.deltaTime;
        }
    }
}
