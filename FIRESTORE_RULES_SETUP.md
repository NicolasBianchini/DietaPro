# Configuração das Regras do Firestore

## Erro: permission-denied

O erro ocorre porque as regras padrão do Firestore exigem autenticação. Como você está usando apenas o Firestore sem Authentication, precisa configurar regras mais permissivas.

## ⚠️ IMPORTANTE: Segurança

As regras abaixo são **apenas para desenvolvimento**. Para produção, você DEVE implementar autenticação ou regras mais restritivas.

## Configuração no Console do Firebase

### 1. Acessar o Console

1. Vá para: https://console.firebase.google.com/
2. Selecione o projeto: **dietapro-f1b95**
3. No menu lateral, clique em **"Firestore Database"**
4. Vá para a aba **"Rules"** (Regras)

### 2. Configurar Regras para Desenvolvimento

Substitua as regras atuais por:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir leitura e escrita para todos (APENAS DESENVOLVIMENTO)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### 3. Publicar as Regras

1. Clique em **"Publish"** (Publicar)
2. Aguarde a confirmação de que as regras foram atualizadas

## Regras Mais Seguras (Recomendado para Produção)

Se quiser uma abordagem mais segura sem autenticação, você pode usar regras baseadas em email:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários podem ler/escrever apenas seus próprios dados
    match /users/{userId} {
      // Permitir leitura por email (você precisaria passar o email como parâmetro)
      allow read: if true; // Temporário - ajustar depois
      allow write: if true; // Temporário - ajustar depois
      
      match /daily_meals/{date} {
        allow read, write: if true;
      }
      
      match /daily_nutrition/{date} {
        allow read, write: if true;
      }
      
      match /custom_foods/{foodId} {
        allow read, write: if true;
      }
    }
    
    // Planos alimentares
    match /meal_plans/{mealPlanId} {
      allow read, write: if true;
    }
  }
}
```

## Verificação

Após configurar as regras:

1. **Aguarde alguns segundos** para as regras serem propagadas
2. **Teste novamente** o login/registro no app
3. O erro de permissão deve desaparecer

## Alternativa: Usar Firestore em Modo de Teste

Se você quiser testar rapidamente, pode habilitar o modo de teste:

1. No console do Firestore, vá em **"Rules"**
2. Clique em **"Get started"** ou **"Start in test mode"**
3. Isso permite leitura/escrita por 30 dias

## Próximos Passos

Após configurar as regras:
1. Teste criar uma conta
2. Teste fazer login
3. Verifique se os dados estão sendo salvos no Firestore

## ⚠️ Lembrete de Segurança

**NUNCA** deixe regras `allow read, write: if true;` em produção!
Isso permite que qualquer pessoa acesse e modifique seus dados.

Para produção, considere:
- Implementar Firebase Authentication
- Criar regras baseadas em validação de dados
- Usar Cloud Functions para validação server-side

