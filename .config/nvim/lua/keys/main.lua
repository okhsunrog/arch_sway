require('keys/alias')

-- Назначает дополнительной клавишей для отключения режима Ctrl + K
im('<C-k>', '<escape>')
vm('<C-k>', '<escape>')
vm('Y', '"+y')
vm('P', '"+p')
