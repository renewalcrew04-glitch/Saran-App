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

export const registerDeviceToken = async (fcmToken) => {
  const platformApplicationArn = process.env.AWS_SNS_PLATFORM_APP_ARN;

  if (!platformApplicationArn) {
    console.warn('AWS_SNS_PLATFORM_APP_ARN not set — push notifications disabled');
    return null;
  }

  try {
    const result = await sns.createPlatformEndpoint({
      PlatformApplicationArn: platformApplicationArn,
      Token: fcmToken,
    }).promise();
    return result.EndpointArn;
  } catch (error) {
    console.error('SNS Register Device Error:', error);
    return null;
  }
};

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