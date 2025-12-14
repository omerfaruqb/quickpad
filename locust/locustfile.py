"""
Locust performance testing script for Quickpad
Simulates realistic user behavior for load testing
"""

from locust import HttpUser, task, between, events
import random
import string
import json

class QuickpadUser(HttpUser):
    """
    Simulates a user interacting with Quickpad
    """
    wait_time = between(1, 3)  # Wait 1-3 seconds between tasks
    
    def on_start(self):
        """Called when a user starts"""
        self.note_id = None
        self.auth_token = None
        
        # Randomly decide if user will sign up/login
        if random.random() < 0.3:  # 30% chance to authenticate
            self.authenticate()
    
    def authenticate(self):
        """Simulate user signup or login"""
        username = ''.join(random.choices(string.ascii_lowercase, k=8))
        email = f"{username}@test.com"
        password = "testpass123"
        
        # Try signup
        signup_response = self.client.post(
            "/api/auth/signup",
            json={
                "username": username,
                "email": email,
                "password": password
            },
            catch_response=True
        )
        
        if signup_response.status_code in [200, 201]:
            data = signup_response.json()
            self.auth_token = data.get("token")
            signup_response.success()
        elif signup_response.status_code == 400:
            # User might already exist, try login
            login_response = self.client.post(
                "/api/auth/login",
                json={
                    "email": email,
                    "password": password
                },
                catch_response=True
            )
            if login_response.status_code == 200:
                data = login_response.json()
                self.auth_token = data.get("token")
                login_response.success()
            else:
                login_response.failure("Login failed")
        else:
            signup_response.failure("Signup failed")
    
    @task(3)
    def create_note(self):
        """Create a new note (most common action)"""
        content = ''.join(random.choices(string.ascii_letters + string.digits + ' \n', k=random.randint(50, 500)))
        
        headers = {}
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        
        response = self.client.post(
            "/api/notes",
            json={"content": content},
            headers=headers,
            catch_response=True
        )
        
        if response.status_code in [200, 201]:
            data = response.json()
            self.note_id = data.get("id") or data.get("url", "").lstrip("/")
            response.success()
        else:
            response.failure(f"Failed to create note: {response.status_code}")
    
    @task(2)
    def read_note(self):
        """Read an existing note"""
        if not self.note_id:
            # Try to read a random note (simulate browsing)
            note_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
        else:
            note_id = self.note_id
        
        response = self.client.get(
            f"/api/notes/{note_id}",
            catch_response=True
        )
        
        if response.status_code == 200:
            response.success()
        elif response.status_code == 404:
            response.success()  # Note not found is acceptable
        else:
            response.failure(f"Failed to read note: {response.status_code}")
    
    @task(1)
    def update_note(self):
        """Update note content"""
        if not self.note_id:
            return
        
        content = ''.join(random.choices(string.ascii_letters + string.digits + ' \n', k=random.randint(50, 500)))
        
        headers = {}
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
        
        response = self.client.put(
            f"/api/notes/{self.note_id}",
            json={"content": content},
            headers=headers,
            catch_response=True
        )
        
        if response.status_code in [200, 204]:
            response.success()
        else:
            response.failure(f"Failed to update note: {response.status_code}")
    
    @task(1)
    def check_health(self):
        """Check API health endpoint"""
        response = self.client.get("/api/health", catch_response=True)
        if response.status_code == 200:
            response.success()
        else:
            response.failure(f"Health check failed: {response.status_code}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Called when the test starts"""
    print("🚀 Starting Locust load test for Quickpad")
    print(f"Target: {environment.host}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Called when the test stops"""
    print("✅ Load test completed")


# Advanced user class for stress testing
class PowerUser(HttpUser):
    """
    Simulates a power user with more frequent actions
    """
    wait_time = between(0.5, 1.5)
    weight = 1  # 10% of users are power users
    
    def on_start(self):
        self.note_ids = []
        self.authenticate()
    
    def authenticate(self):
        """Always authenticate as power user"""
        username = f"poweruser_{''.join(random.choices(string.digits, k=4))}"
        email = f"{username}@test.com"
        password = "testpass123"
        
        response = self.client.post(
            "/api/auth/signup",
            json={"username": username, "email": email, "password": password}
        )
        
        if response.status_code in [200, 201]:
            self.auth_token = response.json().get("token")
    
    @task(5)
    def create_multiple_notes(self):
        """Create multiple notes rapidly"""
        for _ in range(3):
            content = ''.join(random.choices(string.ascii_letters, k=100))
            response = self.client.post(
                "/api/notes",
                json={"content": content},
                headers={"Authorization": f"Bearer {self.auth_token}"}
            )
            if response.status_code in [200, 201]:
                note_id = response.json().get("id")
                if note_id:
                    self.note_ids.append(note_id)
    
    @task(3)
    def update_multiple_notes(self):
        """Update multiple notes"""
        for note_id in self.note_ids[:3]:  # Update first 3 notes
            content = ''.join(random.choices(string.ascii_letters, k=200))
            self.client.put(
                f"/api/notes/{note_id}",
                json={"content": content},
                headers={"Authorization": f"Bearer {self.auth_token}"}
            )

