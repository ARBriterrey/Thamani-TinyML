# Future Improvements

- [ ] **Enforce Specific ESP32 Client Certificates**: Currently, any client with a certificate signed by our Root CA is allowed to connect. In the future, we should configure Nginx to extract the client certificate Subject DN (Identity) and pass it as an HTTP header (e.g., `X-SSL-Client-Subject-DN`) to the Flask orchestrator. The orchestrator can then authorize specific devices based on their identities, dropping connections from revoked, unregistered, or compromised edge devices automatically.
