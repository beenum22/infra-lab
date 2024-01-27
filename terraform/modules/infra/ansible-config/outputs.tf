output "passwords" {
  value = { for k, v in random_password.users : k => v.result }
}