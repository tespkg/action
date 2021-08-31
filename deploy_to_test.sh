echo "---------- run deploy_to_${GITHUB_JOB} --------------"

echo "ALIAS_GITHUB_REPOSITORY: ${ALIAS_GITHUB_REPOSITORY}"
APP_CHART_NAME=`echo ${ALIAS_GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
echo "APP_CHART_NAME: ${APP_CHART_NAME}"

echo "SECOND_MODULE is ${SECOND_MODULE}"
echo "THIRD_MODULE is ${THIRD_MODULE}"

if [ -d "env-${TES_ENV}/${APP_CHART_NAME}" ];then
  if [ ! -d tmp ]; then mkdir tmp ; fi
  cp -v env-${TES_ENV}/${APP_CHART_NAME}/values-test*.yaml tmp/
  rm -rf env-${TES_ENV}/${APP_CHART_NAME}
  cp -r env-${TES_ENV}/${APP_CHART_NAME} env-${TES_ENV}/
  cp -v tmp/values-test*.yaml env-${TES_ENV}/${APP_CHART_NAME}/ && rm -rf tmp
else 
  echo "mkdir -p env-${TES_ENV}/${APP_CHART_NAME}"
  mkdir -p env-${TES_ENV}/${APP_CHART_NAME}
  cp -r env-dev/${APP_CHART_NAME} env-${TES_ENV}/
  file="env-${TES_ENV}/${APP_CHART_NAME}/values-${TES_ENV}.yaml"
  if [ ! -f  $file ];then touch env-${TES_ENV}/${APP_CHART_NAME}/values-${TES_ENV}.yaml fi
fi

echo "------cd env-${TES_ENV}/${APP_CHART_NAME} -----"
cd env-${TES_ENV}/${APP_CHART_NAME}

IMAGE_TAG=`echo ${GITHUB_REF} | awk -F "/" '{print $3}'`
if [[ ${IMAGE_TAG} == v* ]]; then IMAGE_TAG=`echo ${IMAGE_TAG:1}`; fi
echo "replace appVersion and version "
yq w -i Chart.yaml appVersion  --style=double ${IMAGE_TAG}
yq w -i Chart.yaml version  --style=double ${IMAGE_TAG}

if [ "$SECOND_MODULE" == "ignore" ] ;then
echo "------  Reserved the image for ${SECOND_MODULE_FOR_COMMON} due to SECOND_MODULE='ingore'------"
COMMON_FOR_SECOND_MODULE=`echo ${SECOND_MODULE_FOR_COMMON} | awk  '{print $1}'`
echo "------ Name of the image.repo to be reserved:  `yq r values.yaml ${COMMON_FOR_SECOND_MODULE}.image.repository`"
echo "------ Name of the image.tag to be reserved:   `yq r values.yaml ${COMMON_FOR_SECOND_MODULE}.image.tag`"
TAG_FOR_SECOND_MODULE=`yq r values.yaml ${COMMON_FOR_SECOND_MODULE}.image.tag`
fi
if [ "$THIRD_MODULE" == "ignore" ] ;then
echo "------ Reserved image for ${THIRD_MODULE_FOR_COMMON} due to THIRD_MODULE='ingore------"
COMMON_FOR_THIRD_MODULE=`echo ${THIRD_MODULE_FOR_COMMON} | awk  '{print $1}'`
echo "------ Name of the image.repo to be reserved:  `yq r values.yaml ${COMMON_FOR_THIRD_MODULE}.image.repository`"
echo "------ Name of the image.tag to be reserved:   `yq r values.yaml ${COMMON_FOR_THIRD_MODULE}.image.tag`"
TAG_FOR_THIRD_MODULE=`yq r values.yaml ${COMMON_FOR_THIRD_MODULE}.image.tag`
fi

echo "----- list current common*.image.tag -----"
yq r --printMode pv values.yaml "common*.image.tag"
echo "------ replace common*.image.tag to ${IMAGE_TAG} ------"
yq w -i values.yaml "common*.image.tag" ${IMAGE_TAG}
echo "----- list latest common*.image.tag -----"
yq r --printMode pv values.yaml "common*.image.tag"


if [ "$SECOND_MODULE" == "ignore" ];
then
  echo "------ rollback the SECOND_MODULE ------"
  for w in `echo ${SECOND_MODULE_FOR_COMMON}`;
  do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_SECOND_MODULE} && yq r values.yaml ${w}.image.tag;
  done
fi
if [ "$THIRD_MODULE" == "ignore" ];
then
  echo "------ rollback the THIRD_MODULE ------"
  for w in `echo ${THIRD_MODULE_FOR_COMMON}`;
  do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_THIRD_MODULE} && yq r values.yaml ${w}.image.tag;
  done
fi

echo "----- list final common*.image.tag -----"
yq r --printMode pv values.yaml "common*.image.tag"


cd ..
# helmv3 repo add meeraspace ${{ secrets.HELM_REPO_QA }} --username=${{ secrets.HELM_USER }} --password=${{ secrets.HELM_PASSWORD }}
helmv3 repo add meeraspace ${HELM_REPO} --username=${HELM_USER} --password=${HELM_PASSWORD}
helmv3 plugin install https://github.com/chartmuseum/helm-push
helmv3 push ${APP_CHART_NAME} meeraspace --force