using UnityEngine;

namespace Jiayue
{
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
