output "passwords" {
  value = random_password.users
  sensitive = true
}