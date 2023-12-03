import { publicProcedure } from '@/helpers/server/trpc'
import { whatsAppWebhookRequestBodySchema } from '@typebot.io/schemas/features/whatsapp'
import { z } from 'zod'
import { isNotDefined } from '@typebot.io/lib'
import { resumeWhatsAppFlow } from '@typebot.io/bot-engine/whatsapp/resumeWhatsAppFlow'

export const receiveMessage = publicProcedure
  .meta({
    openapi: {
      method: 'POST',
      path: '/workspaces/{workspaceId}/whatsapp/{credentialsId}/webhook',
      summary: 'Message webhook',
      tags: ['WhatsApp'],
    },
  })
  .input(
    z
      .object({ workspaceId: z.string(), credentialsId: z.string() })
      .merge(whatsAppWebhookRequestBodySchema)
  )
  .output(
    z.object({
      message: z.string(),
    })
  )
  .mutation(async ({ input: { entry, credentialsId, workspaceId } }) => {
    const receivedMessage = entry.at(0)?.changes.at(0)?.value.messages?.at(0)
    if (isNotDefined(receivedMessage)) return { message: 'No message found' }
    const contactName =
      entry.at(0)?.changes.at(0)?.value?.contacts?.at(0)?.profile?.name ?? ''
    // const orderDetail = entry.at(0)?.changes.at(0)?.value.messages?.order.product_items?.product_retailer_id
    const contactPhoneNumber =
      entry.at(0)?.changes.at(0)?.value?.messages?.at(0)?.from ?? ''
    const phoneNumberId = entry.at(0)?.changes.at(0)?.value
      .metadata.phone_number_id
    if (!phoneNumberId) return { message: 'No phone number id found' }

    // Check the message type
    const messageType = receivedMessage.type
    console.log(
      'messageType-----',
      messageType,
      '\n\nData:',
      entry.at(0)?.changes.at(0)?.value.messages
    )
    if (messageType === 'order') {
      // Dynamically extract and format order details as text
      const orderText = receivedMessage.order // extractOrderDetails(receivedMessage);

      console.log('orderText', orderText)

      // Pass order details as text input to the chatbot flow
      return resumeWhatsAppFlow({
        receivedMessage: {
          from: receivedMessage.from,
          type: 'text',
          text: {
            body: JSON.stringify(orderText),
          },
          timestamp: receivedMessage.timestamp,
        },
        sessionId: `wa-${phoneNumberId}-${receivedMessage.from}`,
        credentialsId,
        workspaceId,
        contact: {
          name: contactName,
          phoneNumber: contactPhoneNumber,
        },
      })
    }
    return resumeWhatsAppFlow({
      receivedMessage,
      sessionId: `wa-${phoneNumberId}-${receivedMessage.from}`,
      credentialsId,
      workspaceId,
      contact: {
        name: contactName,
        phoneNumber: contactPhoneNumber,
      },
    })
  })
