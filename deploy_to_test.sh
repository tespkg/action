echo "---------- run ${GITHUB_JOB} --------------"
echo "TES_ENV is ${TES_ENV}"

if [ "${TES_ENV}" == "" ]; then
    echo "skip ${GITHUB_JOB} "
    exit 1
fi

echo "ALIAS_GITHUB_REPOSITORY: ${ALIAS_GITHUB_REPOSITORY}"
APP_CHART_NAME=`echo ${ALIAS_GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
echo "APP_CHART_NAME: ${APP_CHART_NAME}"

echo "SECOND_MODULE is ${SECOND_MODULE}"
echo "THIRD_MODULE is ${THIRD_MODULE}"

if [ -d "env-${TES_ENV}/${APP_CHART_NAME}" ];then
  if [ ! -d tmp ]; then mkdir tmp ; fi
  cp -v env-${TES_ENV}/${APP_CHART_NAME}/values-test*.yaml tmp/
  rm -rf env-${TES_ENV}/${APP_CHART_NAME}
  cp -r dev/${APP_CHART_NAME} env-${TES_ENV}/
  cp -v tmp/values-test*.yaml env-${TES_ENV}/${APP_CHART_NAME}/ && rm -rf tmp
else 
  echo "mkdir -p env-${TES_ENV}/${APP_CHART_NAME}"
  mkdir -p env-${TES_ENV}/${APP_CHART_NAME}
  cp -r env-dev/${APP_CHART_NAME} env-${TES_ENV}/
  file="env-${TES_ENV}/${APP_CHART_NAME}/values-${TES_ENV}.yaml"
  if [ ! -f  $file ];then touch env-${TES_ENV}/${APP_CHART_NAME}/values-${TES_ENV}.yaml; fi
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

echo "push the latest SHA: ${GITHUB_SHA:0:8} to the manifest repo ${ALIAS_GITHUB_REPOSITORY}"
git config user.name ${GITHUB_ACTOR}
git config user.email ${GITHUB_ACTOR}@github.com
git diff
git add ./${APP_CHART_NAME}
git pull
git commit -m "${GITHUB_REPOSITORY}_${GITHUB_JOB}_${GITHUB_SHA:0:8}_details:${CI_COMMIT_MESSAGE}"
git push
## error: failed to push some refs to 'git@github.com:tespkg/tes_manifests.git',
## usually caused by another repository pushing
if [ $? == 1 ]; then
    git stash
    git pull -r
    git stash apply
    git push
fi
echo -e "======================= \n\n you can check your application status with 'user/passwd:readonly/Te****g' at \n\n \033[31m https://g-argocd.fluxble.com/applications/${APP_CHART_NAME}\033[0m \n\n======================="