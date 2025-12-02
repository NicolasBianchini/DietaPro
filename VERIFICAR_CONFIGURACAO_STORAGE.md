# 🔍 Verificação Rápida: Configuração do Firebase Storage

## ⚠️ Se ainda está dando erro de autorização, verifique:

### 1️⃣ Autenticação Anônima está habilitada?

1. Acesse: https://console.firebase.google.com
2. Selecione o projeto: **dietapro-f1b95**
3. Vá em **Build** > **Authentication**
4. Clique na aba **Sign-in method**
5. Procure por **Anonymous** (Anônimo)
6. **DEVE ESTAR COM O TOGGLE ATIVADO (verde)**
7. Se não estiver, clique em **Anonymous** e ative o toggle
8. Clique em **Save**

### 2️⃣ Regras do Storage estão aplicadas?

1. No Firebase Console, vá em **Build** > **Storage**
2. Clique na aba **Rules**
3. **Cole exatamente estas regras:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
      allow delete: if request.auth != null;
    }
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

4. Clique em **Publish** (Publicar)

### 3️⃣ Storage está habilitado?

1. No Firebase Console, vá em **Build** > **Storage**
2. Se aparecer uma tela de boas-vindas, clique em **Get Started** (Começar)
3. Escolha o modo de produção (Production mode)
4. Selecione a localização (ex: us-central1)
5. Clique em **Done**

---

## 🧪 Teste Rápido

Após fazer as configurações acima:

1. **Feche completamente o app** (não apenas minimize)
2. **Reabra o app**
3. Tente fazer upload de foto novamente

---

## 📱 Logs para Debug

Se ainda não funcionar, verifique os logs no console do app. Você deve ver:

```
🔐 Criando autenticação anônima para Storage...
✅ Autenticação anônima criada com sucesso: [algum-uid]
📤 Iniciando upload da foto para userId: [seu-user-id]
📁 Caminho do arquivo: profile_photos/profile_[userId]_[timestamp].jpg
✅ Foto enviada com sucesso: [url]
```

Se aparecer:
```
❌ Erro Firebase Auth: operation-not-allowed
```
→ **Autenticação anônima NÃO está habilitada!** Siga o passo 1️⃣ acima.

---

## 🆘 Se Nada Funcionar

Como alternativa temporária (menos seguro), você pode usar estas regras:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{fileName} {
      allow read, write: if true;  // ⚠️ Permite tudo (apenas para desenvolvimento)
    }
  }
}
```

**⚠️ ATENÇÃO:** Estas regras permitem que QUALQUER pessoa faça upload. Use apenas para testar!

---

## ✅ Checklist Final

- [ ] Autenticação Anônima habilitada no Firebase Console
- [ ] Regras do Storage aplicadas e publicadas
- [ ] Storage habilitado no projeto
- [ ] App foi fechado e reaberto após configurações
- [ ] Tentou fazer upload novamente

Se todos os itens estão marcados e ainda não funciona, verifique os logs do app para ver a mensagem de erro exata.

