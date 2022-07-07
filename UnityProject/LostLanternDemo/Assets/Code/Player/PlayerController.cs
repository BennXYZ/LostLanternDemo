using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField]
    Rigidbody rb;

    [SerializeField]
    Camera Charactercamera;

    [SerializeField]
    float sensX;
    [SerializeField]
    float sensY;

    float xRotation;
    float yRotation;

    [SerializeField]
    float speedBuildup;

    [SerializeField]
    float cameraNormalHeight, cameraCrouchingHeight;

    // Start is called before the first frame update
    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
        Charactercamera.transform.localPosition = new Vector3(0, cameraNormalHeight, 0);
    }

    // Update is called once per frame
    void Update()
    {
        ControlCharacter();
        ControlCamera();
    }

    void ControlCharacter()
    {
        float x = Input.GetAxis("Horizontal");
        float y = Input.GetAxis("Vertical");
        bool isRunning = Input.GetKey(KeyCode.LeftShift);
        bool isSneaking = Input.GetKey(KeyCode.LeftControl);

        Vector3 xStrength = Vector3.Cross(Charactercamera.transform.right, Vector3.up) * y * Time.deltaTime * speedBuildup;
        Vector3 yStrength = Charactercamera.transform.right * x * Time.deltaTime * speedBuildup;

        if (isSneaking)
        {
            xStrength = xStrength * 0.5f;
            yStrength = yStrength * 0.5f;
            Charactercamera.transform.localPosition = Vector3.Lerp(Charactercamera.transform.localPosition, new Vector3(0, cameraCrouchingHeight, 0), 0.2f);
        }
        else
        {
            if (isRunning)
            {
                xStrength = xStrength * 2;
                yStrength = yStrength * 2;
            }
            Charactercamera.transform.localPosition = Vector3.Lerp(Charactercamera.transform.localPosition, new Vector3(0, cameraNormalHeight, 0), 0.2f);
        }

        rb.AddForce(xStrength + yStrength);
    }

    void ControlCamera()
    {
        float mouseX = Input.GetAxisRaw("Mouse X") * Time.deltaTime * sensX;
        float mouseY = Input.GetAxisRaw("Mouse Y") * Time.deltaTime * sensX;

        yRotation += mouseX;
        xRotation -= mouseY;

        xRotation = Mathf.Clamp(xRotation, -60f, 60f);
        Charactercamera.transform.rotation = Quaternion.Euler(xRotation, yRotation, 0);
        //transform.rotation = Quaternion.Euler(0, yRotation, 0);
    }
}
