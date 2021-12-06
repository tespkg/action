echo "ALIAS_GITHUB_REPOSITORY: ${ALIAS_GITHUB_REPOSITORY}"
APP_CHART_NAME=`echo ${ALIAS_GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
echo "APP_CHART_NAME: ${APP_CHART_NAME}"


echo "SECOND_MODULE is ${SECOND_MODULE}"
echo "THIRD_MODULE is ${THIRD_MODULE}"
echo "FOURTH_MODULE is ${FOURTH_MODULE}"

IMAGE_TAG=`echo ${GITHUB_REF} | awk -F "/" '{print $3}'`

if [[ ${IMAGE_TAG} =~ "mixedmanual" ]]; then
  echo "run non-Standard deployment"
  echo "cd  env-mixed/${APP_CHART_NAME}-${BRANCH_NAME}"
  cd env-mixed/${APP_CHART_NAME}-${BRANCH_NAME} || exit 1
else
  echo "run Standard deployment"
  echo "cd env-${TES_ENV}/${APP_CHART_NAME}"
  cd env-${TES_ENV}/${APP_CHART_NAME}
  if [ $? != 0 ]; then
      echo "err, no such directory env-${TES_ENV}/${APP_CHART_NAME} "
      exit 1
  fi
fi  

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
if [ "$FOURTH_MODULE" == "ignore" ] ;then
echo "------ Reserved image for ${FOURTH_MODULE_FOR_COMMON} due to FOURTH_MODULE=ingore   ------"
COMMON_FOR_FOURTH_MODULE=`echo ${FOURTH_MODULE_FOR_COMMON} | awk  '{print $1}'`
echo "------ Name of the image.repo to be reserved:  `yq r values.yaml ${COMMON_FOR_FOURTH_MODULE}.image.repository`"
echo "------ Name of the image.tag to be reserved:   `yq r values.yaml ${COMMON_FOR_FOURTH_MODULE}.image.tag`"
TAG_FOR_FOURTH_MODULE=`yq r values.yaml ${COMMON_FOR_FOURTH_MODULE}.image.tag`
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
if [ "$FOURTH_MODULE" == "ignore" ];
then
  echo "------ rollback the FOURTH_MODULE ------"
  for w in `echo ${FOURTH_MODULE_FOR_COMMON}`;
  do yq w -i values.yaml ${w}.image.tag ${TAG_FOR_FOURTH_MODULE} && yq r values.yaml ${w}.image.tag;
  done
fi

echo "----- list final common*.image.tag -----"
yq r --printMode pv values.yaml "common*.image.tag"

cd ..
# helmv3 repo add meeraspace ${{ secrets.HELM_REPO_QA }} --username=${{ secrets.HELM_USER }} --password=${{ secrets.HELM_PASSWORD }}
helmv3 repo add meeraspace ${HELM_REPO} --username=${HELM_USER} --password=${HELM_PASSWORD}
helmv3 plugin install https://github.com/chartmuseum/helm-push

if [[ ${IMAGE_TAG} =~ "mixedmanual" ]]; then
  helmv3 cm-push ${APP_CHART_NAME}-${BRANCH_NAME} meeraspace --force || exit 1
else
  helmv3 cm-push ${APP_CHART_NAME} meeraspace --force || exit 1
fi