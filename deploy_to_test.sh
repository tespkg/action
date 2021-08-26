echo "---------- run deploy_to_${TES_ENV} --------------"

cd helm/${APP_PROJECT_NAME}
EXPECT_CHART=`echo ${GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
TARGET_CHART=`yq r ${APP_CHART_NAME}/Chart.yaml name`
echo "verify the EXPECT_CHART:$EXPECT_CHART and TARGET_CHART:$TARGET_CHART"
if [ "$EXPECT_CHART" != "$TARGET_CHART" ];then
echo "TARGET_CHART $TARGET_CHART not same as EXPECT_CHART $EXPECT_CHART, please check"
exit 1
fi

if [ ! -d tmp ]; then mkdir tmp ; fi
if [ -d "0-env-${TES_ENV}/${APP_CHART_NAME}" ];then
  cp -v ./0-env-${TES_ENV}/${APP_CHART_NAME}/values-test*.yaml tmp/
  rm -rf ./0-env-${TES_ENV}/${APP_CHART_NAME}
  cp -r ${APP_CHART_NAME} 0-env-${TES_ENV}/
  cp -v tmp/values-test*.yaml ./0-env-${TES_ENV}/${APP_CHART_NAME}/ && rm -rf tmp
else 
  mkdir -p 0-env-${TES_ENV}/${APP_CHART_NAME}
  cp -r ${APP_CHART_NAME} 0-env-${TES_ENV}/
  file="0-env-${TES_ENV}/${APP_CHART_NAME}/values-${TES_ENV}.yaml"
  if [ ! -f  $file ];then
    touch 0-env-${TES_ENV}/${APP_CHART_NAME}/values-${TES_ENV}.yaml
  fi
fi

env

cd 0-env-${TES_ENV}
IMAGE_TAG=`echo ${GITHUB_REF} | awk -F "/" '{print $3}'`
if [[ ${IMAGE_TAG} == v* ]]; then IMAGE_TAG=`echo ${IMAGE_TAG:1}`; fi
echo "replace appVersion and version "
yq w -i ${APP_CHART_NAME}/Chart.yaml appVersion  --style=double ${IMAGE_TAG}
yq w -i ${APP_CHART_NAME}/Chart.yaml version  --style=double ${IMAGE_TAG}
yq w -i ${APP_CHART_NAME}/values.yaml "common*.image.tag" ${IMAGE_TAG}

helmv3 repo add meeraspace ${{ secrets.HELM_REPO_QA }} --username=${{ secrets.HELM_USER }} --password=${{ secrets.HELM_PASSWORD }}
helmv3 plugin install https://github.com/chartmuseum/helm-push
helmv3 push ${APP_CHART_NAME} meeraspace