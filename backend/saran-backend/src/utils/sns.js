import AWS from 'aws-sdk';
import dotenv from 'dotenv';

dotenv.config();

AWS.config.update({
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  // ✅ CORRECT: We use the variable name here, not the value!
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
});

const sns = new AWS.SNS();

export const sendPush = async (endpointArn, payload) => {
  if (!endpointArn) return;

  try {
    const message = {
      default: payload.title,
      GCM: JSON.stringify({
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data || {},
      }),
    };

    await sns.publish({
      MessageStructure: 'json',
      Message: JSON.stringify(message),
      TargetArn: endpointArn,
    }).promise();
  } catch (error) {
    console.error('SNS Push Error:', error);
  }
};