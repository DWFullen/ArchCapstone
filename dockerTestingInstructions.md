# Docker Local Testing Workflow

## 1. Build the Docker Image
<!-- Must navigate to directory with docker file -->
```Powershell Terminal
docker build -t myblazorapp:latest .
```

## 2. Run the Container
```Powershell Terminal
docker run -d -p 80:80 myblazorapp:latest
```

## 3. Verify the Container is Running
```Powershell Terminal
docker ps
```

## 4. View Container Logs
```Powershell Terminal
docker logs <container_id>
```
*Get `<container_id>` from the output of `docker ps`.*

## 5. Access the Application
Open your browser and go to: [http://localhost:80](http://localhost:80)

## 6. Stop the Container After Testing
```Powershell Terminal
docker stop <container_id>
```

## 7. Remove the Container (optional)
```Powershell Terminal
docker rm <container_id>
```

---

**Tips:**
- If you make code changes, rebuild the image before running again.
- Use `docker logs -f <container_id>` to follow logs in real time.
- Change the port mapping (`-p 8080:80`) if port 80 is in use.